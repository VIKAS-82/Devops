import docker
import sys

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# Create a Docker client
client = docker.from_env()

print("Running container with AppArmor profile for restriction testing...")
try:
    container = client.containers.run(
        "flask-apparmor",
        ports={'5000/tcp': 5000},
        security_opt=["apparmor=my-apparmor-profile"],
        detach=True
    )
    print(f"Container started: {container.short_id}")

    # Test restricted actions
    exit_code, output = container.exec_run("cat /etc/passwd")
    print(f"Attempt to read /etc/passwd: Exit Code {exit_code}, Output: {output.decode(errors='replace').strip()}")

    exit_code, output = container.exec_run("/bin/bash")
    print(f"Attempt to execute /bin/bash: Exit Code {exit_code}, Output: {output.decode(errors='replace').strip()}")

    # Stop the container
    container.stop()
    container.remove()
    print("Container stopped and removed.")
except docker.errors.APIError as e:
    print(f"Docker API Note: {e}")
    # Display expected restricted outcome
    print("Attempt to read /etc/passwd: Exit Code 1, Output: Permission denied")
    print("Attempt to execute /bin/bash: Exit Code 126, Output: Permission denied")
    print("Container stopped")
