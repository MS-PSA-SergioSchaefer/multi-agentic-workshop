# Lab 03: Mark v2 with a Semantic Model

Microsoft Fabric – create and evaluate a Fabric data agent grounded in the `sm_retail` semantic model.

## 🎯 Mission Brief

In this lab, you create **Mark v2** without changing the SQL-based Mark agent from Lab 02. Mark v2 uses the curated `sm_retail` semantic model and its explicit DAX measures instead of querying the `db_retail` tables directly with SQL.

In Fabric IQ terms, this lab hardens the **measure layer**. Everything you configure here (measure names, descriptions, AI data schema, AI instructions, verified answers) is reused later: in Lab 04, Generate Ontology turns these measures into ontology **metrics**, and Mark IQ keeps routing every monetary question to this model.

You then run the same benchmark questions against:

- **Mark v1:** `db_retail` SQL database source.
- **Mark v2:** `sm_retail` semantic model source.

The goal is to measure whether the semantic model improves metric consistency, relationship handling, and answer quality.

## Goals

By completing this lab, you will:

1. Preserve Mark v1 as the SQL-source baseline.
2. Prepare `sm_retail` for AI consumption.
3. Create a new data agent named `Mark v2`.
4. Configure Mark v2 to use the semantic model and its measures.
5. Run a repeatable comparison between Mark v1 and Mark v2.
6. Publish Mark v2 as a separate agent.

---

## 1. Prerequisites

Complete the following labs first:

- [Lab 01 - Data setup and semantic model](lab01-data-setup.en.md)
- [Lab 02 - Mark v1 with a SQL source](lab02-mark-facts-agent.en.md)

Confirm that:

- `db_retail` contains the `customer`, `orders`, `orderline`, and `product` tables.
- The `sm_retail` semantic model contains the same four tables.
- The relationships defined in Lab 01 are active.
- The custom measures from Lab 01 are available.
- Mark v1 still uses the SQL database source.

> [!IMPORTANT]
> Do not replace Mark v1's source. Keeping Mark v1 unchanged provides a stable baseline for the comparison.

---

## 2. Prepare `sm_retail` for AI

The semantic model is not only a query source. Its names, descriptions, relationships, measures, and AI configuration determine how accurately a data agent generates DAX.

> [!NOTE]
> Example queries (question-and-SQL pairs like the ones you added to Mark v1) aren't supported for semantic model sources. For a semantic model, the equivalent levers are **Prep data for AI** (AI data schema, AI instructions, and verified answers) and good descriptions.

### a. Review the model relationships

Confirm these active relationships:

| One side | Many side | Cardinality |
|---|---|---|
| `customer[CustomerId]` | `orders[CustomerId]` | 1:* |
| `orders[OrderId]` | `orderline[OrderId]` | 1:* |
| `product[ProductID]` | `orderline[ProductID]` | 1:* |

Use single-direction filtering from the one side to the many side unless the model has a tested business requirement for another configuration.

### b. Configure Prep data for AI

1. Open `sm_retail`.
2. Select **Prep data for AI**.
3. Open **Simplify the data schema**.
4. Include only the objects Mark v2 needs.

Recommended AI data schema:

| Table | Recommended columns |
|---|---|
| `customer` | `CustomerId`, `FirstName`, `LastName`, and the customer attributes used in workshop questions |
| `orders` | `OrderId`, `OrderNumber`, `CustomerId`, `OrderDate`, `OrderStatus`, `SubTotal`, `TaxAmount`, `OrderTotal` |
| `orderline` | `OrderId`, `OrderLineNumber`, `ProductID`, `Quantity`, `UnitPrice`, `LineTotal`, `DiscountAmount`, `TaxAmount` |
| `product` | `ProductID`, `ProductName`, `BrandName`, `CategoryName`, `ListPrice`, `StandardCost` |

Include these explicit measures:

- `Product Count`
- `Customer Count`
- `Order Count`
- `Total Order Subtotal`
- `Total Order Tax`
- `Total Order Value`
- `Average Order Value`
- `Total Sales`
- `Total Quantity`
- `Total Discount Amount`
- `Total Tax Amount`
- `Discount % of Sales`
- `Tax % of Sales`

Include all columns and measures on which the selected measures depend.

### c. Add business-friendly descriptions and terminology

All configuration in this workshop is performed in the Microsoft Fabric web experience. Power BI Desktop isn't required.

#### Add descriptions in the Fabric model editor

1. In the Fabric workspace, locate `sm_retail`.
2. Select **... > Open semantic model**, or open the model from its details page.
3. Switch from **Viewing mode** to **Editing mode**.
4. In **Model view**, select a table, column, or measure in the **Data** pane.
5. Expand the **Properties** pane.
6. Enter the business definition in **Description**.

For a measure, you can enter the description manually or select **Create with Copilot** under the Description box when that feature is available. Review generated descriptions before saving them.

Use descriptions that explain:

- What the object represents.
- The calculation grain, such as order header or order line.
- Important inclusions or exclusions.
- The intended business use.

Example:

```text
Total Sales: Sum of orderline[LineTotal] in the current filter context. Use this measure for product and order-line revenue analysis; it is not interchangeable with Total Order Value.
```

#### Configure alternative terminology in Fabric

The Fabric web experience for a service-authored Direct Lake model doesn't provide the legacy Power BI Desktop Q&A synonym editor. Use the Fabric-native AI configuration instead:

1. Open `sm_retail`.
2. Select **Prep data for AI**.
3. Open **AI instructions**.
4. Add the terminology mapping below.
5. Select **Apply**.

```markdown
## Business terminology

- Treat "client" and "buyer" as alternative terms for customer.
- Treat "purchase" and "transaction" as alternative terms for order.
- Treat "order detail", "line item", and "purchased item" as alternative terms for order line.
- Treat "item" and "merchandise" as alternative terms for product.
- Treat "line sales", "sales amount", and "product sales" as Total Sales.
- Treat "order value" and "total order amount" as Total Order Value.
- Treat "AOV" and "average purchase value" as Average Order Value.
- Treat "discount rate" and "discount percentage" as Discount % of Sales.
```

Also keep object names business-friendly and add alternative user phrasings as trigger phrases for verified answers.

| Model object | Alternative terminology |
|---|---|
| `customer` | customer, client, buyer |
| `orders` | order, purchase, transaction |
| `orderline` | order detail, line item, purchased item |
| `product` | product, item, merchandise |
| `Total Sales` | line sales, sales amount, product sales |
| `Total Order Value` | order value, total order amount |
| `Average Order Value` | AOV, average purchase value |
| `Discount % of Sales` | discount rate, discount percentage |

### d. Add verified answers (optional)

Verified answers aren't required to create or use Mark v2. Skip this section if you want to evaluate the semantic model and its metadata without predefined answers.

Use verified answers only for important, repeated, or ambiguous questions where you want to guide the generated DAX toward an approved combination of measures, fields, and filters. Verified answers are saved to the semantic model, but you author them from a visual in a Power BI report. This entire procedure can be completed in the Fabric web experience; Power BI Desktop isn't required.

#### Create the report used to author verified answers

1. In the Fabric workspace, locate `sm_retail`.
2. Select **... > Create report**.
3. Create a report in the Fabric web report editor.
4. Add a visual that answers one benchmark question using the intended dimensions, measures, and filters.
5. Save the report in the workspace with a name such as `sm_retail AI validation`.

#### Configure a verified answer

1. Open the report in **Edit** mode.
2. Select the visual that contains the approved answer.
3. Open the visual's **...** menu.
4. Select **Set up a verified answer**.
5. Enter the primary trigger phrase and alternative phrasings.
6. Review the visual, filters, and measures.
7. Save the verified answer.

Create verified answers for common or high-value questions, such as:

- "What are the product details for order F100241?"
- "Show Total Order Value and Order Count by year."
- "Show the top 5 products by Total Sales."

All verified answers created from the report are stored on `sm_retail`, not only on that report. You can manage them later from **sm_retail > Prep data for AI**.

> [!NOTE]
> For semantic-model queries, the data agent's DAX generation primarily uses semantic-model metadata and **Prep data for AI**. Agent-level instructions do not replace correct model relationships, measure definitions, or AI schema configuration.

---

## 3. Create Mark v2

1. In the Fabric workspace, select **+ New item**.
2. Search for and select **Data agent**.
3. Name the agent `Mark v2`.
4. Select **Add a data source**.
5. Select the `sm_retail` semantic model.
6. Select the `customer`, `orders`, `orderline`, and `product` tables.
7. Confirm that the measures configured in the AI data schema are available.
8. If your tenant shows optional preview settings for the data agent (for example a newer runtime), leave them at their defaults for the benchmark so Mark v1, Mark v2, and Mark IQ are compared under the same conditions.

Do not add `db_retail` as a second source to Mark v2. This lab is designed to isolate the effect of moving from SQL to a semantic model.

---

## 4. Configure Mark v2 instructions

Open **Agent instructions** and add:

```markdown
# Role

You are Mark v2, the Contoso Retail analytical data agent.

# Scope

Answer questions about customers, orders, order lines, products, sales, quantities, discounts, taxes, and order values by using the sm_retail semantic model.

# Metric rules

- Prefer explicit semantic-model measures over implicit aggregation of numeric columns.
- Use Total Order Value, Total Order Subtotal, Total Order Tax, Order Count, and Average Order Value for order-header analysis.
- Use Total Sales, Total Quantity, Total Discount Amount, Total Tax Amount, Discount % of Sales, and Tax % of Sales for order-line and product analysis.
- Do not treat Total Sales and Total Order Value as interchangeable. State the grain when both are used.
- Preserve the user's requested filters and time period.

# Response rules

- State the metric and filter context used.
- Use tables for multi-row results.
- If the question is ambiguous, explain the interpretation used.
- Do not invent unavailable values.
- When no matching data is found, say so clearly.
```

These instructions control Mark v2's scope, source preference, and response behavior. The semantic model remains responsible for DAX calculation logic.

---

## 5. Run the Mark comparison benchmark

Start a new chat before testing each agent. Ask the following questions exactly as written and in the same order.

### Benchmark questions

| ID | Question | Capability being tested |
|---|---|---|
| Q1 | **What are the orders from Omar Bennett? Return OrderNumber, OrderDate, OrderStatus, and Total Order Value.** | Customer lookup and customer-to-order relationship |
| Q2 | **What products were included in order F100241? Return product name, quantity, unit price, line total, discount amount, and tax amount.** | Order-to-line-to-product traversal |
| Q3 | **What did Omar Bennett buy? Group the result by order and include the product details.** | Multi-table relationship traversal |
| Q4 | **For customer CID-069, show Order Count, Total Order Subtotal, Total Order Tax, Total Order Value, and Average Order Value between July 1, 2019 and May 31, 2021.** | Date filtering and order-level measures |
| Q5 | **Show the top 5 products by Total Sales, including Total Quantity and Total Discount Amount.** | Ranking and line-level measures |
| Q6 | **Show Total Sales, Total Discount Amount, Discount % of Sales, and Tax % of Sales by product category.** | Percentages, grouping, and product relationships |
| Q7 | **Show Order Count, Customer Count, Total Order Value, and Average Order Value by year.** | Time aggregation and mixed measures |
| Q8 | **Compare Total Sales from order lines with Total Order Value from order headers. Explain why they may differ.** | Calculation grain and explanation quality |

### Record the results

Use one row per question and agent.

| Question | Agent | Answer returned | Correct values | Correct filters | Correct relationships | Correct metric grain | Notes |
|---|---|---|---|---|---|---|---|
| Q1 | Mark v1 |  | Pass/Fail | Pass/Fail | Pass/Fail | N/A |  |
| Q1 | Mark v2 |  | Pass/Fail | Pass/Fail | Pass/Fail | N/A |  |
| Q2 | Mark v1 |  | Pass/Fail | Pass/Fail | Pass/Fail | N/A |  |
| Q2 | Mark v2 |  | Pass/Fail | Pass/Fail | Pass/Fail | N/A |  |

Continue the table through Q8.

### Scoring

Score each applicable criterion as one point:

1. Returned the correct rows or aggregate values.
2. Applied all requested filters.
3. Traversed the correct relationships.
4. Used the intended measure and calculation grain.
5. Explained the result without unsupported claims.

Use the same trusted report or manually validated query as the reference for both agents.

### Expected differences

- Mark v1 might reconstruct calculations directly from SQL columns.
- Mark v2 should prefer the explicit, governed measures in `sm_retail`.
- Mark v2 should be more consistent for repeated KPI questions and alternative phrasings.
- Transaction-detail questions might produce similar results in both versions.
- Any numerical disagreement must be investigated; do not assume the newer agent is automatically correct.

---

## 6. Publish Mark v2

1. Select **Publish**.
2. Use a description such as:

   `Contoso Retail analytical agent grounded in the sm_retail semantic model and governed DAX measures.`

3. Publish Mark v2 as a separate agent.
4. Do not overwrite Mark v1 while the comparison is in progress.

---

## Mission Complete

You now have a SQL-based Mark v1 and a semantic-model-based Mark v2, along with a repeatable benchmark for comparing their accuracy and behavior.

Mark v2 knows *how to calculate* the business, but it still doesn't know *what the business is*: what a customer, a sales order, or an order line means, how they connect, and which business rules apply. That is the job of the Fabric IQ ontology in the next lab.

Continue to [Lab 04 - Mark with Fabric IQ ontology](lab04-mark-fabric-iq-ontology.en.md).
