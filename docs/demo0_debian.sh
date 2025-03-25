#!/usr/bin/env bash
UBUNTU_IMG="ubuntu-24.04-server-cloudimg-amd64.img"
USER_DATA_FILE="user-data"
META_DATA_FILE="meta-data"

print_red()
{
  local msg="$1"
  echo -e "\e[31m${msg}\e[0m"
}

prnt_cmd()
{
  local cmd="$1"
  print_red "${cmd}"
  sleep 1
}

hndl_err()
{
  local err=$1
  if [ ${err} != 0 ]; then
    echo "Error executing ${cmd}"
    exit 1
  fi

}

exec_cmd_silent()
{
  local cmd="$1"
  prnt_cmd "${cmd}"
  eval "${cmd}" > /dev/null 2>&1
  hndl_err $?
}

exec_cmd()
{
  local cmd="$1"
  prnt_cmd "${cmd}"
  eval "${cmd}"
  hndl_err $?
}

exec_ssh()
{
  local ssh_cmd="ssh -p 2222 -o StrictHostKeyChecking=no vmuser@localhost \"$1\""
  prnt_cmd "${ssh_cmd}"
  eval ${ssh_cmd}
}

pause()
{
  sleep 3
}

clean()
{
  for f in qemu seed.img seed.qcow2 ${USER_DATA_FILE} ${META_DATA_FILE} ${UBUNTU_IMG} ; do
    exec_cmd "rm -rf ${f}"
  done
  ssh-keygen -f ~/.ssh/known_hosts -R '[localhost]:2222'
}

PUB_KEY=
KERNEL_BDIR=
if [ "$#" -eq 2 ]; then
  PUB_KEY="$1"
  KERNEL_BDIR="$2"
else
  echo "You are missing arguments:"
  echo "Usage: demo0_debian.sh <public key path> <kerne build dir>"
  exit
fi

print_red "* clean current directory"
pause
clean

print_red "* Install Deps"
pause
exec_cmd "sudo apt-get install git mkisofs"

print_red "* Shallow clone pcie-testdev branch in https://github.com/Joelgranados/qemu.git"
pause
exec_cmd "git clone --depth 1 -b pcie-testdev https://github.com/Joelgranados/qemu.git"

print_red "* build qemu"
pause
exec_cmd "pushd qemu"
exec_cmd_silent "./configure --target-list=x86_64-softmmu --disable-docs"
exec_cmd_silent "make -s -j32"
exec_cmd "popd"

print_red "* download cloud image"
pause
exec_cmd "wget https://cloud-images.ubuntu.com/releases/noble/release/${UBUNTU_IMG}"

pub_key="$(<"${PUB_KEY}")"
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

power_state:
  mode: poweroff
  condition: true
"

cat > ${USER_DATA_FILE} <<EOF
${USER_DATA_STR}
EOF


META_DATA_STR="
#cloud-config
"
cat > ${META_DATA_FILE} <<EOF
${META_DATA_STR}
EOF

print_red "* create cloud init setup file"
pause
exec_cmd "mkisofs -output seed.img -volid cidata -joliet -rock ${USER_DATA_FILE} ${META_DATA_FILE}"

qemu_cmd="sudo ./qemu/build/qemu-system-x86_64 \
            -nodefaults \
            -display none \
            -machine q35,accel=kvm,kernel-irqchip=split \
            -cpu host -smp 4 -m 8G \
            -device intel-iommu,intremap=on,device-iotlb=on,x-scalable-mode=on \
            -netdev user,id=net0,hostfwd=tcp::2222-:22 \
            -device virtio-net-pci,netdev=net0 \
            -device virtio-rng-pci \
            -drive id=boot,file=${UBUNTU_IMG},format=qcow2,if=virtio,discard=unmap,media=disk,read-only=no \
            -device pcie-ats-testdev"

print_red "* Prep Qemu"
pause
exec_cmd_silent "${qemu_cmd} \
            -serial mon:stdio \
            -drive id=cloud-init-seed,file=seed.img,format=raw,media=cdrom"

print_red "* Exec Qemu"
pause
exec_cmd_silent "${qemu_cmd} \
            -daemonize \
            -kernel ${KERNEL_BDIR}/arch/x86_64/boot/bzImage \
            -append \"root=/dev/vda1 console=ttyS0,115200 audit=0 earlyprintk=serial nokaslr\" \
            -virtfs local,path=${KERNEL_BDIR},security_model=none,readonly=on,mount_tag=kernel_dir"

pause

LIBVFN_INST_DIR="/home/vmuser/libvfn/inst/"
LIBVFN_PKG="${LIBVFN_INST_DIR}/lib/x86_64-linux-gnu/pkgconfig"
PACKAGES="git meson libnvme-dev pkg-config python3 python3-pytest python3-pyudev"

print_red "* Install deps in VM"
pause
exec_ssh "sudo apt-get update > /dev/null 2>&1"
exec_ssh "yes \"\" | sudo apt-get install ${PACKAGES} > /dev/null 2>&1"

print_red "* Build libvfn"
pause
exec_ssh "git clone https://github.com/SamsungDS/libvfn.git > /dev/null 2>&1"
exec_ssh "pushd libvfn && meson setup builddir --prefix=${LIBVFN_INST_DIR} > /dev/null 2>&1"
exec_ssh "pushd libvfn && meson compile -C builddir > /dev/null 2>&1"
exec_ssh "pushd libvfn && meson install -C builddir > /dev/null 2>&1"

print_red "* build iommutests"
pause
exec_ssh "git clone https://github.com/SamsungDS/iommutests.git > /dev/null 2>&1"
exec_ssh "pushd iommutests && meson setup builddir -Dpkg_config_path=${LIBVFN_PKG} > /dev/null 2>&1"
exec_ssh "pushd iommutests && meson compile -C builddir > /dev/null 2>&1"

print_red "* Run iommutests"
pause
exec_ssh "pushd iommutests/builddir && sudo pytest -rs"
exec_ssh "sudo poweroff"

