# Sonic Pi Build Farm

This project contains scripts to automate virtual machine management
for building and testing Sonic Pi on Linux.

It assumes that the following commands all exist and your user has
permission to run them:

- docker-compose
- erb
- python -m venv
- ruby
- virsh
- virt-install
- cloud-localds

On ubuntu, `sudo libvirt-clients virtinst cloud-image-utils`

## Work in Progress

Proceed with caution and low expectations.

## Cloud Images

Cloud images are disk images built to run on public and private
cloud infrastructure like AWS, Azure, and OpenStack.

We use cloud images in our build farm where possible because they're
small, and they are easy to configure on boot with
[cloud-init](http://cloudinit.readthedocs.io/en/latest/index.html).

We can destroy the farm and rebuild from scratch in seconds without
the hassle of installing from an ISO image or maintaining our own
fleet of run ready images.

## Running the Farm

Run `librarian.rb list` to see the images this project knows
about.  Download one or more with `librarian.rb download`.

Open `cloud-init/userdata.txt.erb` and update the apt proxy
configuration to your local apt proxy (or delete that section all
together).

Run `create-vms.sh`.

Run `build-metadata-files.sh`

Run `configure-vms.sh`.

Open [buildbot](http://localhost:8080/)

## Next Steps

### Image Management

(Work in Progress) Include metadata in the project to allow the farm
to download images for itself.  Let the user add or remove images from
a list as they please, and let the project deal with downloads and
updates.

### Automated Builds

Right now we're left with VMs that aren't doing any work.  That's
pretty underwhelming.  Script the installation of build prerequisites and
actually build Sonic Pi on all the farm members.

### Package Creation

Once we're building from source, it won't be a stretch to create unofficial
daily build packages.
