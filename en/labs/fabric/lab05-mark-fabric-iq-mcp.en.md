# Lab 05 (optional): Mark Everywhere – Fabric IQ through MCP

Microsoft Fabric – consume `retail_ontology` outside Fabric through the **ontology MCP server**, from VS Code and from a Copilot Studio agent.

## 🎯 Mission Brief

In Lab 04 you captured the Contoso Retail business vocabulary (entities, relationships, rules) once, in `retail_ontology`. The point of Fabric IQ is that this knowledge isn't locked inside one data agent: every agent should reason over the **same** definitions.

In this lab you expose the ontology through the Model Context Protocol (MCP) and use it from:

1. **VS Code** agent mode, as a developer would.
2. A **Copilot Studio** agent, through the **Fabric IQ MCP** tool. This is the same platform where you build Bill in Labs 06–11.

## 🔎 Goals

1. Find the ontology MCP endpoint for `retail_ontology`.
2. Connect VS Code to it and ask business questions.
3. Create a Copilot Studio agent that uses the Fabric IQ MCP tool.
4. Compare its answers with Mark IQ.

> [!IMPORTANT]
> The ontology MCP server and the Fabric IQ MCP tool in Copilot Studio are in preview. A service principal can't currently access the ontology MCP server; sign in with a user account.

---

## 1. Prerequisites

- Lab 04 completed: `retail_ontology` passes build checks C1–C10.
- An F2 or higher capacity (or Power BI Premium P1 or higher).
- Tenant settings **Users can create ontology (preview) items** and **Users can create Fabric items**.
- For section 4: a Copilot Studio **production** environment in which ontology MCP tools are allowed by your admin's data policies.

---

## 2. Get the ontology MCP endpoint

1. Open `retail_ontology` in the browser.
2. Copy two values from the URL:
   - The **workspace ID**: the segment after `groups/`.
   - The **ontology item ID**: the segment after `ontologies/`.
3. Build the endpoint:

   ```text
   https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/<workspace-ID>/items/<ontology-item-ID>/ontologyEndpoint
   ```

Keep these IDs; you need them again in section 4.

---

## 3. Use the ontology from VS Code

1. In a local folder, create `.vscode/mcp.json`, or open the Command Palette and select **MCP: Add Server**.
2. Select **HTTP**, paste the endpoint from section 2, and name the server `retail-ontology`. The resulting file looks like this:

   ```json
   {
     "servers": {
       "retail-ontology": {
         "type": "http",
         "url": "https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/<workspace-ID>/items/<ontology-item-ID>/ontologyEndpoint"
       }
     }
   }
   ```

3. Start the server and select **Allow** to sign in with your Microsoft Entra ID account.
4. Open Copilot Chat in **Agent** mode and confirm that the `retail-ontology` tools are listed, for example `list_ontology_entity_types`, `search_ontology`, and `list_ontology_rules`.
5. Ask:
   - `Using retail-ontology, list the entity types and relationship types.`
   - `Using retail-ontology, list the business rules and explain what an open order is.`
   - `Using retail-ontology, which products were sold in the sales order whose OrderNumber is F100241?`
   - `Using retail-ontology, which VIP customers have open orders?`
6. Compare the IDs with the reference queries O2 and O5 from Lab 04.

Notice that the agent in VS Code never saw your Mark IQ instructions. It understands "open order" and "VIP" because the rules live in the ontology.

---

## 4. Use the ontology from Copilot Studio

1. In Copilot Studio, select your production environment.
2. Select **Agents > + Create blank agent** and name it `Mark IQ Studio`.
3. Add instructions:

   ```markdown
   You answer questions about Contoso Retail customers, sales orders, order lines, and products by using the Fabric IQ ontology tool.
   - Apply the ontology business rules (for example open orders and VIP customers).
   - Users identify orders by OrderNumber, such as F100241.
   - Don't calculate monetary totals. If the user asks for sales or order values, say that governed financial metrics are answered by the Mark data agent.
   - Don't invent entities. If nothing matches, say so.
   ```

4. Select **Tools > + Add tool**, search for **Fabric IQ**, and select **Fabric IQ MCP (Preview)**.
5. Under **Connection**, select **Create new connection**, keep **Login with Microsoft Entra ID**, and select **Create**.
6. Enter the **Workspace ID** and **Ontology ID** from section 2, then select **Add**.
7. Confirm that the tool exposes `list_ontology_entity_types` and `search_ontology`.
8. In **Test**, ask a question. When prompted, select **Allow**, then **Open connection manager > Connect**, and **Retry**.
9. Ask the O1–O5 questions from Lab 04 and record whether the answers match the reference queries.

---

## 5. Compare and decide

| Question | Mark IQ (data agent) | VS Code + MCP | Mark IQ Studio | Same entities? |
|---|---|---|---|---|
| O2 – products in F100241 |  |  |  | Yes/No |
| O3 – customer of F100241 |  |  |  | Yes/No |
| O5 – open orders of VIP customers |  |  |  | Yes/No |
| Q9 – VIP open orders with Total Order Value |  |  |  | Yes/No |

Expected outcome: the three consumers agree on entities and business terms because they share one ontology. Only Mark IQ returns governed monetary values, because it also has `sm_retail`. That separation is intentional:

- **Ontology (Fabric IQ)** – what the business is and how it connects.
- **Semantic model** – how the business is measured.
- **Agents** – how people ask.

In Lab 09, Bill can call Mark IQ for governed facts and numbers, and agents such as Mark IQ Studio can reuse the ontology directly for entity reasoning.

---

## 6. Go further (optional)

The ontology can also ground other agent types. These options are in preview; check the documentation for current steps:

- **Fabric operations agent** grounded in the ontology: monitors ontology data with natural-language instructions and can notify you in Microsoft Teams. Idea: notify when a VIP customer has an open order older than 30 days.
- **Foundry IQ agent** grounded in the ontology, to combine `retail_ontology` with the product documents used by Anders in the Foundry labs.

References:

- [Agent integration options for ontology](https://learn.microsoft.com/en-us/fabric/iq/ontology/concepts-agent-integration)
- [Consume ontology as an MCP server](https://learn.microsoft.com/en-us/fabric/iq/ontology/how-to-use-ontology-mcp-server)
- [Build a Copilot Studio agent grounded in an ontology](https://learn.microsoft.com/en-us/fabric/iq/ontology/how-to-create-agent-copilot-studio)

---

## Mission Complete

The Contoso Retail business vocabulary is now defined once in Fabric IQ and consumed by a Fabric data agent, a developer tool, and a Copilot Studio agent. Continue with the [Microsoft Foundry labs](../../readme.md#laboratories).
