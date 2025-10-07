#!/bin/bash
set -euo pipefail

# Configuration
MOUNT_POINT="/data"
FILESYSTEM="ext4"
LOG_FILE="/var/log/auto-mount.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check if a device is the root device or part of root filesystem
is_root_device() {
    local device="$1"
    local root_device

    # Get the root device (remove partition number if present)
    root_device=$(findmnt -n -o SOURCE / | sed 's/[0-9]*$//')

    # Check if the device is the root device or a partition of it
    if [[ "$device" == "$root_device"* ]] || [[ "$root_device" == "$device"* ]]; then
        return 0  # true - it's a root device
    fi

    return 1  # false - not a root device
}

# Function to check if device is already mounted
is_mounted() {
    local device="$1"
    mountpoint=$(findmnt -n -o TARGET "$device" 2>/dev/null || echo "")
    [[ -n "$mountpoint" ]]
}

# Function to format and mount device
format_and_mount() {
    local device="$1"

    log "Formatting device $device with $FILESYSTEM filesystem"

    # Create filesystem
    if ! mkfs."$FILESYSTEM" -F "$device" >> "$LOG_FILE" 2>&1; then
        log "ERROR: Failed to format $device"
        return 1
    fi

    # Create mount point
    if [[ ! -d "$MOUNT_POINT" ]]; then
        mkdir -p "$MOUNT_POINT"
        log "Created mount point $MOUNT_POINT"
    fi

    # Mount the device
    if ! mount "$device" "$MOUNT_POINT"; then
        log "ERROR: Failed to mount $device to $MOUNT_POINT"
        return 1
    fi

    log "Successfully mounted $device to $MOUNT_POINT"

    # Get UUID for persistent mounting
    local uuid
    uuid=$(blkid -s UUID -o value "$device")

    # Add to /etc/fstab for persistent mounting
    if ! grep -q "$uuid" /etc/fstab; then
        echo "UUID=$uuid $MOUNT_POINT $FILESYSTEM defaults,nofail 0 2" >> /etc/fstab
        log "Added $device (UUID=$uuid) to /etc/fstab"
    fi

    # Set appropriate permissions
    chmod 755 "$MOUNT_POINT"

    return 0
}

# Main execution
mount_data() {
    log "Starting auto-mount script"

    # Wait for devices to be ready
    sleep 5

    # Get list of all block devices (excluding loop, ram, and sr devices)
    local devices
    devices=$(lsblk -dpno NAME | grep -E '^/dev/(sd|xvd|nvme)' || true)

    if [[ -z "$devices" ]]; then
        log "No suitable block devices found"
        exit 0
    fi

    local mounted_count=0

    # Process each device
    while IFS= read -r device; do
        [[ -z "$device" ]] && continue

        log "Checking device: $device"

        # Skip if it's the root device
        if is_root_device "$device"; then
            log "Skipping $device - it's the root device or part of root filesystem"
            continue
        fi

        # Skip if already mounted
        if is_mounted "$device"; then
            local current_mount
            current_mount=$(findmnt -n -o TARGET "$device")
            log "Skipping $device - already mounted at $current_mount"
            continue
        fi

        # Check if device has partitions
        local partitions
        partitions=$(lsblk -no NAME "$device" | tail -n +2 | sed "s|^|/dev/|" || true)

        if [[ -n "$partitions" ]]; then
            log "Device $device has partitions, checking partitions instead"
            while IFS= read -r partition; do
                [[ -z "$partition" ]] && continue

                if ! is_root_device "$partition" && ! is_mounted "$partition"; then
                    log "Found unmounted non-root partition: $partition"
                    if format_and_mount "$partition"; then
                        mounted_count=$((mounted_count + 1))
                        break  # Only mount one device/partition
                    fi
                fi
            done <<< "$partitions"
        else
            # No partitions, format the whole device
            log "Found unmounted non-root device: $device"
            if format_and_mount "$device"; then
                mounted_count=$((mounted_count + 1))
            fi
        fi

        # Break after successfully mounting one device
        if [[ $mounted_count -gt 0 ]]; then
            break
        fi

    done <<< "$devices"

    if [[ $mounted_count -eq 0 ]]; then
        log "No additional devices found to mount"
    else
        log "Successfully processed $mounted_count device(s)"
    fi

    log "Auto-mount script completed"
}

mount_data

mkdir -p /opt/monitoring
cat > /opt/monitoring/buckets.yaml <<END
mimir_bucket: ${mimir_bucket}
loki_bucket: ${loki_bucket}
tempo_bucket: ${tempo_bucket}
backup_bucket: ${backup_bucket}
END

groupadd ansible
useradd -m -s /bin/bash -g ansible ansible
usermod -aG sudo ansible
echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible

mkdir -p /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
chown ansible:ansible /home/ansible/.ssh

cat > /home/ansible/.ssh/ansible <<END
${ssh_private_key}
END
cat > /home/ansible/.ssh/ansible.pub <<END
${ssh_public_key}
END
cp /home/ansible/.ssh/ansible.pub /home/ansible/.ssh/authorized_keys

cat > /home/ansible/.ssh/config <<END
Host *
  StrictHostKeyChecking no
  ForwardAgent yes
  ControlPath ~/.ssh/%C
  ControlMaster auto
  ControlPersist 600
  ServerAliveInterval 60
  ServerAliveCountMax 2
END
chown -R ansible:ansible /home/ansible/.ssh/ansible /home/ansible/.ssh/ansible.pub /home/ansible/.ssh/config /home/ansible/.ssh/authorized_keys
chmod 600 /home/ansible/.ssh/ansible /home/ansible/.ssh/ansible.pub /home/ansible/.ssh/config /home/ansible/.ssh/authorized_keys


mkdir -p /root/.ssh
cp /home/ansible/.ssh/ansible* /home/ansible/.ssh/authorized_keys /root/.ssh/
cp /home/ansible/.ssh/config /root/.ssh/
chmod 600 /root/.ssh/ansible /root/.ssh/ansible.pub /root/.ssh/config /home/ansible/.ssh/authorized_keys

cat > /etc/profile.d/ansible.sh <<END
export CLOUD_ENVIRONMENT=aws
export ANSIBLE_ROLE=tag_Role_${role}
export ANSIBLE_USER=ansible
export ANSIBLE_INVENTORY="/opt/ansible-monitoring/inventory/aws_ec2.yaml"
export LOAD_BALANCER=${load_balancer}
export ANSIBLE_STACK=tag_Stack_${stack}
END

cat > /etc/default/wizard <<END
CLOUD_ENVIRONMENT=aws
ANSIBLE_ROLE=tag_Role_${role}
ANSIBLE_STACK=tag_Stack_${stack}
ANSIBLE_USER=ansible
ANSIBLE_INVENTORY="/opt/ansible-monitoring/inventory/aws_ec2.yaml"
LOAD_BALANCER=${load_balancer}
END

cat > /etc/ssl/private/monitoring.key <<END
${tls_private_key}
END
cat > /etc/ssl/certs/monitoring.crt <<END
${tls_cert}
END

/usr/sbin/update-ca-certificates || /bin/true

systemctl daemon-reload
systemctl restart wizard
