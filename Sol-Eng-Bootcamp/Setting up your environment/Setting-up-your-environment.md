# ⚙️ Setting up your environment

[🏠 Back to Home](../README.md)

> Before building and governing the agents, prepare your tenant. This guide walks through the prerequisite setup steps, starting with assigning your admin user to the **Agent 365 Trial** license.

## Index

- [Step 1: Assign your admin user to the Agent 365 Trial license](#step-1-assign-your-admin-user-to-the-agent-365-trial-license)
- [Step 2: Set up the Power Platform admin environment](#step-2-set-up-the-power-platform-admin-environment)
- [Step 3: Assign Dataverse to the Contoso default environment](#step-3-assign-dataverse-to-the-contoso-default-environment)
- [Step 4: Create a new Production environment](#step-4-create-a-new-production-environment)

---

## Step 1: Assign your admin user to the Agent 365 Trial license

Your admin account needs the **Agent 365 Trial** license assigned before it can publish and govern agents through Agent 365.

1. Sign in to the **Microsoft 365 admin center** (`https://admin.cloud.microsoft`).
2. In the left rail, go to **Billing → Your products**.
3. In the **Products** list, select **Agent 365 Trial**.
4. Open the **Licenses** tab and select **+ Assign licenses**.
5. Search for and select your **admin user**, then choose **Assign**.
6. Confirm the assignment — the **Assigned licenses** count for **Agent 365 Trial** increases by one.

> The Agent 365 Trial includes 100 licenses. Assigning your admin user consumes one and unlocks the Agents experience used throughout the rest of the bootcamp.

---

## Step 2: Set up the Power Platform admin environment

Create a **pay-as-you-go billing plan** in the Power Platform admin center so Copilot Studio usage bills to your Azure subscription.

1. Sign in to the **Power Platform admin center** (`https://admin.powerplatform.microsoft.com`).
2. In the left rail, go to **Licensing → Billing Plans**.
3. Select **+ New billing plan**.
4. Fill in the **New billing plan** panel:
   - **Name**: assign a **unique name** for your plan.
   - **Azure subscription**: select the Azure subscription to bill to.
   - **Resource group**: keep the default selection.
   - **Meter**: select **Copilot Studio**.
   - **Region**: **United States**.
5. Accept the remaining defaults and select **Next** through the wizard.
6. **Create** the billing plan. Confirm it appears in the **Billing plans** list with **Status = Enabled**.

> A pay-as-you-go plan turns on Azure billing for the resources in the selected environments, so Copilot Studio consumption is metered to your Azure subscription.

---

## Step 3: Assign Dataverse to the Contoso default environment

The **Contoso (default)** environment needs **Dataverse** so the agents have a backing data store.

1. In the **Power Platform admin center** (`https://admin.powerplatform.microsoft.com`), go to **Manage → Environments**.
2. Select the **Contoso (default)** environment to open its details.
3. Confirm the environment **State = Ready** and **Region = United States**.
4. From the top toolbar, select **Resources → Dataverse** (or **Settings**) and assign **Dataverse** to the environment if it is not already provisioned.
5. Wait for provisioning to complete, then confirm the **Dataverse version** appears under the environment's **Version** card.

> Dataverse is the data platform the Copilot Studio agent relies on. The default environment must have it assigned before building the agent.

---

## Step 4: Create a new Production environment

Create a dedicated **Production** environment, in the **same region as the billing plan**, with Dataverse and pay-as-you-go billing tied to the billing policy you created in Step 2.

1. In the **Power Platform admin center** (`https://admin.powerplatform.microsoft.com`), go to **Manage → Environments**.
2. Select **+ New**.
3. Fill in the environment details:
   - **Type**: **Production**.
   - **Region**: select the **same region as your billing plan** (e.g. **United States - Default**).
   - **Name**: assign a **unique name**.
4. Expand **Change default settings** and configure:
   - **Get new features early**: **Yes**.
   - **Add a Dataverse data store?**: **Yes**.
   - **Pay-as-you-go with Azure?**: **Yes**.
   - **Billing policy**: select the billing policy you created in Step 2.
5. Select **Next** to open the **Add Dataverse** panel:
   - **Language**: **English (United States)**.
   - **Currency**: **USD ($)**.
   - **Security group**: select **+ Select** and pick **All Company**.
   - Leave the remaining options at their defaults.
6. Select **Save**. Wait for provisioning to complete — the new environment appears in the **Environments** list with **State = Ready** and **Dataverse = Yes**.

> Creating the environment with pay-as-you-go and the billing policy ensures Copilot Studio usage in this environment bills to your Azure subscription.

---

[🏠 Back to Home](../README.md)
