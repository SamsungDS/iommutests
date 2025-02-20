import pytest
import pyudev
import os
import os.path

sys_pci_ctx =  pyudev.Context()

def do_check_file(file_path):
    if not os.path.exists(file_path):
        pytest.skip("Skipping test: {file_path} is missing")
    return file_path

@pytest.fixture
def check_file():
    return do_check_file

@pytest.fixture
def pci_dev_enumer(request):
    if not isinstance(request.param, dict):
        pytest.fail("Argument to get_pci_enumer must be a dictionary")
    if len(request.param) < 1:
        pytest.fail("Dictionary argument must have at least one element")

    dev_enumer = sys_pci_ctx.list_devices(subsystem = "pci")
    for key,val in request.param.items():
        dev_enumer = dev_enumer.match_attribute(key, val)

    return dev_enumer

def do_unbind_from_driver(dev):
    # return if it is already unbound
    if dev.driver == None:
        return;

    v_id = dev.attributes.asstring('vendor').removeprefix('0x')
    d_id = dev.attributes.asstring('device').removeprefix('0x')

    # Unbind from current driver
    try:
        with open(os.path.join(dev.sys_path, "driver", "unbind")) as drv_file:
            drv_file.write(dev.sys_name)
    except Exception as e:
        pytest.fail(f"Could not unbind {dev.sys_name} from its driver: {e}")

    # Remove ID from current driver
    try:
        with open(os.path.join(dev.sys_path, "driver", "remove-id")) as removeid_file:
            removeid_file.write(f"{v_id} {d_id}")
    except Exception as e:
        pytest.fail(f"Could not remove {dev.sys_name} ID from its driver: {e}")


def do_bind_to_vfio_pci(dev):
    # return if already bound
    if dev.driver == "vfio-pci":
        return;

    vfio_pci_syspath = "/sys/bus/pci/drivers/vfio-pci"
    if not os.path.isdir(vfio_pci_syspath):
        # Incorrect environment is not a failure. Skip with an informative message
        pytest.skip(f"Path not found: {vfio_pci_syspath}; Are CONFIG_VFIO "
                    "and CONFIG_VFIO_PCI missing from Kernel conf?")

    v_id = dev.attributes.asstring('vendor').removeprefix('0x')
    d_id = dev.attributes.asstring('device').removeprefix('0x')

    # Add new ID to the vfio-pci driver
    try:
        with open(os.path.join(vfio_pci_syspath, "new_id"), 'w') as newid_file:
            newid_file.write(f"{v_id} {d_id}")
    except Exception as e:
        # "new_id" failed, try to use "bind".
        try:
            with open(os.path.join(vfio_pci_syspath, "bind"), 'w') as bind_file:
                bind_file.write(dev.sys_name)
        except Exception as e:
            pytest.fail(f"Could not bind {dev.sys_name} to vfio-pci: {e}")

def do_mod_binding_vfio_pci(dev, unbind_only=False):
    if not isinstance(dev, pyudev.Device):
        pytest.fail("Arg to do_mod_binding_vfio_pci must be a pyudev Device")

    # Make sure we get the latest device state
    dev = pyudev.Device.from_sys_path(sys_pci_ctx, dev.sys_path)
    if dev.driver is not None:
        do_unbind_from_driver(dev)

    if not unbind_only:
        do_bind_to_vfio_pci(dev)

@pytest.fixture
def mod_binding_vfio_pci():
    return do_mod_binding_vfio_pci


