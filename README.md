# minimal-os

```bash
# Build the Docker image (first time takes ~5 minutes)
docker-compose build

# Start the container
docker-compose up -d

# Verify it's running
docker ps | grep osdev
# You should see: osdev-environment
```

```bash
# Enter your development environment
docker exec -it osdev-environment bash

# You should now see: osdev@[container-id]:/workspace$

# Run the verification script
./verify-environment.sh

# All checks should show green ✓ marks
```

If any checks fail, rebuild: `exit` then `docker-compose build --no-cache`