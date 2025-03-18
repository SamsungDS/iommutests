#!/usr/bin/env bash
UBUNTU_IMG="ubuntu-24.04-server-cloudimg-amd64.img"
USER_DATA_FILE="user-data"
META_DATA_FILE="meta-data"

exec_cmd()
{
  local cmd="$1"
  echo "${cmd}"
  ${cmd}

  if [ $? != 0 ]; then
    echo "Error executing ${cmd}"
    exit 1
  fi
}

exec_ssh()
{
  local cmd="$1"
  echo "${cmd}"
  ssh -p 2222 vmuser@localhost "${cmd}"
}

pause()
{
  sleep 0
  #sleep 5
}

clean()
{
  for f in qemu seed.img seed.qcow2 ${USER_DATA_FILE} ${META_DATA_FILE} ${UBUNTU_IMG} ; do
    exec_cmd "rm -rfv ${f}"
  done
  ssh-keygen -f ~/.ssh/known_hosts -R '[localhost]:2222'
}

echo "* clean current directory"
clean

echo "* Install Deps"
exec_cmd "sudo apt-get install git mkisofs"
pause

echo "* Shallow clone qemu https://github.com/Joelgranados/qemu.git"
exec_cmd "git clone --depth 1 -b pcie-testdev https://github.com/Joelgranados/qemu.git"
pause

echo "* build qemu"
exec_cmd "pushd qemu"
exec_cmd "./configure --target-list=x86_64-softmmu --disable-docs"
exec_cmd "make -j32"
exec_cmd "popd"

echo "* download cloud image"
exec_cmd "wget https://cloud-images.ubuntu.com/releases/noble/release/${UBUNTU_IMG}"

pub_key="$(<"$HOME/.ssh/id_ed25519.pub")"
USER_DATA_STR="
#cloud-config
disable_root: false
ssh_pwauth: false
users:
  - name: vmuser
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    home: /home/vmuser
    shell: /bin/bash
    lock_passwd: false
    plain_text_passwd: 'vmuser'
    ssh_authorized_keys:
      -  ${pub_key}
"

cat > ${USER_DATA_FILE} <<EOF
${USER_DATA_STR}
EOF


META_DATA_STR="
#cloud-config
power_state:
  mode: poweroff
  condition: true
"
cat > ${META_DATA_FILE} <<EOF
${META_DATA_STR}
EOF

echo "* create cloud init setup file"
exec_cmd "mkisofs -output seed.img -volid cidata -joliet -rock ${USER_DATA_FILE} ${META_DATA_FILE}"

echo "* Execute Qemu"
qemu_cmd="sudo ./qemu/build/qemu-system-x86_64
            -nodefaults
            -display none
            -machine q35,accel=kvm,kernel-irqchip=split
            -cpu host -smp 4 -m 8G
            -device intel-iommu,intremap=on,device-iotlb=on,x-scalable-mode=on
            -netdev user,id=net0,hostfwd=tcp::2222-:22
            -device virtio-net-pci,netdev=net0
            -device virtio-rng-pci
            -drive id=boot,file=${UBUNTU_IMG},format=qcow2,if=virtio,discard=unmap,media=disk,read-only=no
            -device pcie-ats-testdev"

#-serial mon:stdio
exec_cmd "${qemu_cmd}
            -daemonize
            -drive id=cloud-init-seed,file=seed.img,format=raw,media=cdrom"

sleep 5

LIBVFN_INST_DIR="/home/vmuser/libvfn/inst/"
LIBVFN_PKG="${LIBVFN_INST_DIR}/lib/x86_64-linux-gnu/pkgconfig"
PACKAGES="meson libnvme-dev pkg-config python3 python3-pytest python3-pyudev"
exec_ssh "sudo apt-get update"
exec_ssh "yes \"\" | sudo apt-get install git ${PACKAGES}"
exec_ssh "git clone https://github.com/SamsungDS/libvfn.git"
exec_ssh "pushd libvfn && meson setup builddir --prefix=${LIBVFN_INST_DIR}"
exec_ssh "pushd libvfn && meson compile -C builddir"
exec_ssh "pushd libvfn && meson install -C builddir"
exec_ssh "git clone https://github.com/SamsungDS/iommutests.git"
exec_ssh "pushd iommutests && meson setup builddir -Dpkg_config_path=${LIBVFN_PKG}"
exec_ssh "pushd iommutests && meson compile -C builddir"
exec_ssh "pushd iommutests/builddir && pytest -rs"

