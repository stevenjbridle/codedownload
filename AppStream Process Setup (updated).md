# App Stream Builder Image Setup

The following process steps you through the one-time setup process for creating an AWS AppStream 2.0 Builder Image, with application updates on launch.

This process covers the applications:

- Microsoft PowerBI Desktop
- Microsoft SQL Server Management Studio
- Google Chrome

## Prerequisites

This process assumes you are either starting from a fresh Builder Image, or have uninstalled all versions of the above 3 applications.

## 1. Package Manager Installation

Applications are installed and updated through the Chocolatey package manager.

[➡ View script `1-install-chocolatey.ps1`](./AppStreamImageSetup/1-install-chocolatey.ps1)

## 2. Application Installation

Install the packages with Chocolatey.

The command below will deliberately install older versions of both PowerBI and SQL Server Management Studio, so that the update process can be tested/validated.

[➡ View script `2-install-apps.ps1`](./AppStreamImageSetup/2-install-apps.ps1)

Once done, capture evidence of the installed versions for later reference:

[➡ View script `7-verify-installed-versions.ps1`](./AppStreamImageSetup/7-verify-installed-versions.ps1)

> Note down the versions of the 3 applications as they are listed here.

## 3. Install Updater Script

Run the following script to create a app-updater file in C:/Scripts

> Note: if you are prompted about saving content with Unicode, select Accept/Yes.

[➡ View script `3-app-updater-script.ps1`](./AppStreamImageSetup/3-app-updater-script.ps1)

## 4. Setup Task Scheduler

The `AppStream-AppUpdate.ps1` script will be set to trigger on system boot by Task Scheduler.

Open a PowerShell window as Administrator, and copy/paste in the following script to run it immediately.

You do not need to save this as a file on the Builder Image, as it only needs to be setup the once.

You should not receive any errors, and the final two lines should produce results detailing the Task that has been setup.

[➡ View script `4-setup-task-scheduler.ps1`](./AppStreamImageSetup/4-setup-task-scheduler.ps1)

## 5. Import Apps to Image Assistant

Import the 3 applications into the Image Assistant.

[➡ View script `5-register-apps-image-asis.ps1`](./AppStreamImageSetup/5-register-apps-image-asis.ps1)

## 6. Configure Apps

Using the Image Assistant, you should now perform any pre-configuration of the applications as you wish.

This is not explained here.

When complete, snapshot your new Image from this Builder Image through the Image Assistant.

```powershell
image-assistant.exe create-image --name "<example-image-name>"
```

> On running this, you will be disconnected from the Builder Image whilst it creates the new image.

## 7. Test AppStream-AppUpdate.ps1

Test the script works as intended by manually creating a new Builder Image from the newly snapshot Image.

Once connected to the new Builder Image, verify that the applications have now updated:

[➡ View script `7-verify-installed-versions.ps1`](./AppStreamImageSetup/7-verify-installed-versions.ps1)

For both PowerBI and SQL Server Management Studio, you should now see the latest versions are installed.


## 8. Deploy AppStream Updater Lambda Stack

Deploy the Lambda and Step Function setup using AWS CLI:

Replace parameters to your created base image and subnets.
```bash
aws cloudformation deploy \
  --template-file appstream-image-updater-agd.yaml \
  --stack-name appstream-image-updater \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    AppStreamFleetName=agd-test-fleet \
    AppStreamBaseImageName=AutoImage-20250729-0557 \
    AppStreamImageBuilderInstanceType=stream.standard.medium \
    VpcId=vpc-0985a9333e869005c \
    SubnetId=subnet-0d4bc7fd28d57f70e \
    SecurityGroupId=sg-0496413bcf1431895
```

Once deployed, go to the **AWS Console > Step Functions**, find the state machine named something like `AppStreamImageUpdater`, and click **Start Execution**.

You can provide inputs like:

```json
{
 "state": "INIT" 
}
```

Monitor progress and logs in the Step Function UI.

## URLS  & Endpoints

|                              |                                           |
| :--------------------------- | :---------------------------------------- |
| Community Package Repository | https://community.chocolatey.org/api/v2/  |
| Community Feed               | https://community.chocolatey.org/packages |