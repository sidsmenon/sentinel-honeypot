# Azure Sentinel — Honeypot Threat Analysis

This project uses Azure Sentinel SIEM to analyze failed RDP login attempts on an internet-exposed Windows VM. Security events from the VM's Event Manager are sent to Azure Sentinel via Azure Log Analytics. The attacker’s public IP is extracted from the logs and sent to ipgeolocation.io to obtain latitude and longitude details. This data is then plotted on a world map in an Azure Sentinel workbook to visualize the origin and frequency of the attacks.

A detailed walkthrough of this project can be found here: https://sidharthsmenon.medium.com/azure-sentinel-honeypot-threat-analysis-d92ad9263f8a
