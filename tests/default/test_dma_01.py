import subprocess
import os.path
import pprint

def dma_01():
    cmd = [os.path.join(os.path.dirname(__file__), "dma_01")]
    result = subprocess.run(cmd ,stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    pprint.pprint (result.__dict__)
    return result.returncode == 0

def test_dma_01(capsys):
    assert dma_01() == True
    print (capsys.readouterr())

