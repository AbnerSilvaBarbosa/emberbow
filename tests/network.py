"""Real ENet integration test: one host and three clients on localhost."""
import subprocess, sys, time
from pathlib import Path
root = Path(__file__).resolve().parents[1]
engine = str(Path(sys.argv[1]).resolve())
def launch(flag):
    return subprocess.Popen([engine, '--headless', '--log-file', '/tmp/emberbow-net-' + str(time.time_ns()) + '.log', '--path', str(root), '--script', 'tests/net_peer.gd', '--', flag], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
processes = []
try:
    host = launch('--host-test'); processes.append(host)
    time.sleep(.5)
    for _ in range(3):
        processes.append(launch('--join-test'))
        time.sleep(.2)
    failed = False
    for i, proc in enumerate(processes):
        output = proc.communicate(timeout=18)[0]
        print(output)
        expected = 'NETWORK_PASS: host' if i == 0 else 'NETWORK_PASS: client'
        failed |= bool(proc.returncode or expected not in output or 'ERROR:' in output or 'above the MTU' in output)
    sys.exit(1 if failed else 0)
finally:
    for proc in processes:
        if proc.poll() is None: proc.kill()
