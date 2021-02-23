# Cray EX User Access Nodes Installation Guide

> version: @product_version@
>
> build date: @date@

This document describes the installation prequisites, installation procedures,
and operational procedures for Cray EX User Access Nodes (UAN).

## Table of Contents

1. [Installation Prerequisites](prereqs/index.md)

    Topics:
    * Management Network Switch Configuration
    * BMC Configuration
    * BIOS configuration
    * UAN BMC Firmware
    * Software Prerequisites

1. [UAN Software Installation](install/index.md)

    Topics:
    * Download and Prepare the UAN Software Package
    * Run the Installation Script (Online Install)
    * Run the Installation Script (Offline/air-gapped Install)
    * Installation Verification

1. [Operational Tasks](operations/index.md)

    Topics:
    * Overall Workflow
    * UAN Image Pre-boot Configuration
    * Customizing UAN images
    * Preparing UAN Boot Session Templates
    * Booting UAN Nodes

1. [Advanced Topics](advanced/index.md)

    Topics:
    * Building the UAN image using the Cray Image Management System (IMS)

[comment]: <> (    * Customizing UANs Manually)
[comment]: <> (    * Debugging UAN configuration and booting issues)
    * Building UAN images from recipes
    * Customizing UANs Manually
    * [Debugging UAN Booting Issues](advanced/debug_boot.md)
    * [Debugging UAN Configuration Issues](advanced/debug_config.md)
