# IntuneMDM
A Repo For Intune Scripts

`ManagedDevicesAppsReport`

Detecting Apps with Intune on devices is possible but is completed in the GUI one device at a time. This report is a complete dump of all devices, users and detected apps into a csv. I then use PowerBI to find all devices with a particular app, or select a user and check their detected apps.

You dont need PBi, Excel does the same job and is easier to set up.

You will need a user with `Application Administrator` or `Global Adminisrator` in Azure, to consent to the scopes. The script will prompt for authorization.

Expect a little time to complete the report, depending on the Users, Devices and the number of apps as the script iterates through all items.

`IntuneAPIs`

A work in progress for the generation of reports for Intune, some beta SDK commands and APIs seem to have bugs that require running a report firstly in the browser before working.
Files are generated for each report with Date columns for appending in PBi reports
