#!/bin/bash
set -e
st2 run packs.install subtree=true repo_url=StackStorm/st2tests packs=tests,asserts,fixtures,webui
sudo cp -R /usr/share/doc/st2/examples /opt/stackstorm/packs/
st2 run packs.setup_virtualenv packs=examples
st2ctl reload