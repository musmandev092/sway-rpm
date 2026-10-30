#!/bin/bash
# Runs inside a fedora:44 container. Rebuilds Rawhide's wlroots and sway for Fedora 44 and
# publishes them (signed) into /work/pages/fc44/x86_64.
set -euo pipefail
WORK=/work; PAGES=$WORK/pages; OUT=$WORK/out; SRPM=$WORK/srpm
RAW=https://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/source/tree/
mkdir -p "$OUT" "$SRPM" "$PAGES/fc44/x86_64"

dnf -y install rpm-build rpm-sign dnf-plugins-core createrepo_c gnupg2 >/dev/null
dnf download --repofrompath=rawsrc,$RAW --repo=rawsrc --setopt=rawsrc.gpgcheck=0 --destdir "$SRPM" wlroots sway
W=$(ls "$SRPM"/wlroots-*.src.rpm); S=$(ls "$SRPM"/sway-*.src.rpm)
NEW="$(basename "$W") $(basename "$S")"
echo "Rawhide has: $NEW"
if [ "${FORCE:-false}" != true ] && [ -f "$PAGES/state.txt" ] && [ "$(cat "$PAGES/state.txt")" = "$NEW" ]; then
    echo "Already published, nothing to do."; echo "changed=false" >> "${GITHUB_OUTPUT:-/dev/null}"; exit 0
fi

dnf -y builddep --setopt=install_weak_deps=False "$W"
rpmbuild --rebuild --define "_rpmdir $OUT" "$W"
dnf -y install "$OUT"/x86_64/wlroots-[0-9]*.rpm "$OUT"/x86_64/wlroots-devel-*.rpm
dnf -y builddep --setopt=install_weak_deps=False "$S"
rpmbuild --rebuild --define "_rpmdir $OUT" "$S"

DEST=$PAGES/fc44/x86_64
rm -f "$DEST"/*.rpm
cp "$OUT"/x86_64/wlroots-[0-9]*.rpm "$OUT"/x86_64/sway-[0-9]*.rpm "$DEST"/

export GNUPGHOME=$(mktemp -d); chmod 700 "$GNUPGHOME"
printf '%s' "$SIGNING_KEY" | gpg --batch --import
FPR=$(gpg --list-keys --with-colons | awk -F: '/^fpr/{print $10; exit}')
rpmsign --define "_gpg_name $FPR" --define "__gpg_sign_cmd %{__gpg} gpg --batch --no-verbose --no-armor --pinentry-mode loopback --no-secmem-warning -u %{_gpg_name} -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}" --addsign "$DEST"/*.rpm
createrepo_c --update "$DEST"
cp "$WORK/RPM-GPG-KEY-sway-rpm.asc" "$WORK/sway-rpm.repo" "$PAGES/"
echo "$NEW" > "$PAGES/state.txt"
echo "changed=true" >> "${GITHUB_OUTPUT:-/dev/null}"
