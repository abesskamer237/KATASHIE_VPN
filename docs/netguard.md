### How to Use NetGuard
- NetGuard starts automatically after installation from the panel.
- Automatically starts on system reboot.
- Host blocklists are updated automatically.

### How to Create a Custom Host Blocklist
1. Create a text file containing the hosts you want to block (you can host it on GitHub or another service).
2. Add blocked hosts in the following format:
   0.0.0.0 example-block-host.com
3. Save the file.

### How to Add a Host List from a URL
1. Copy the URL of your text file containing blocked hosts.
2. In the NetGuard panel, go to **Add Host List**.
3. Paste the URL and save.
4. The rules will reload automatically.

**Note:**
- To force an immediate update, click the "Update Host" button.
- Make sure your file uses the correct format for all entries.
