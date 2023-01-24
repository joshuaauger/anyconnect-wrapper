#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title anyconnect vpn
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 🔒
# @raycast.packageName Raycast Scripts
# @raycast.argument1 { "type": "text", "placeholder": "VPN: connect/disconnect" }
# @raycast.argument2 { "type": "text", "placeholder": "Agent: enable/disable", "optional": true }

ARG=$1
case $ARG in
	connect) vpn --plaintext --connect;;
	disconnect) vpn --plaintext --disconnect;;
	status) vpn --plaintext --status;;
esac

ARG=$2
case $ARG in
	enable) vpn --plaintext --agent enable;;
	disable) vpn --plaintext --agent disable;;
	status) vpn --plaintext --agent status;;
esac