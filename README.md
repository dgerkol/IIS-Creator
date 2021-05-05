# IIS-Creator
A PowerShell script for automated generic IIS site creation based on a provided configuration file.

The IIS-creator is in charge of creating an HTTP, HTTPS & FTP sites instantely based on a provided simple configuration file which defins supported HTTP VERBS, URLs, URIs, content-types and etc.

It is in charge of creating physical paths, DNS zones, site settings (including virtual directories, port numbers, authentication and etc..), basic security configurations and certificate self-signing.

If needed, it may also revert any changes and comepletely delete a website with all changes made at the host OS.

Provided by a task list - users may also choose to automate only some of its capabilities, and create sub-automations as well.
