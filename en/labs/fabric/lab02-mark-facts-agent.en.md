# Lab 02: Mark v1 – Data Agent over the SQL Database

Microsoft Fabric – create and configure **Mark v1**, a Fabric data agent grounded directly in the `db_retail` SQL tables.

## 🎯 Mission Brief

In this lab you create **Mark v1**, a Fabric data agent that answers natural-language questions about Contoso Retail orders, customers, and products by generating read-only SQL over `db_retail`.

Mark v1 is deliberately the *raw-data* baseline of the Fabric IQ journey: it only knows table and column names plus the instructions you give it. In Lab 03 you add governed semantics (Mark v2), and in Lab 04 you add a Fabric IQ ontology (Mark IQ). Running the same questions against all three shows what each layer contributes.

## 🔎 Goals

By completing this lab you will:

1. Create the data agent **Mark**.
2. Test its answers and observe where raw tables fall short.
3. Improve it with agent instructions, data source instructions, and example queries.
4. Publish the data agent.
5. Preserve Mark as the SQL baseline for the next labs.

---

## 1. Create the data agent "Mark"

> [!NOTE]
> The Fabric data agent is generally available. Older screenshots show the item as **Data Agent (preview)**; the current item is named **Data agent**.

### a. Select the option to create a new item

![New Item](images/M1.a.png)

### b. Search for "agent"

### c. Select **Data agent**

![New Item Type](images/M1.c.png)

### d. Name it "Mark" and select **Create**

![Agent Name](images/M1.d.png)

### e. Select **Add a data source**

![Data Source](images/M1.e.png)

### f. Select the `db_retail` SQL database created in Lab 01

![SQL Database](images/M1.f.png)

### g. Select only the following tables

i. `customer`
ii. `orderline`
iii. `orders`
iv. `product`

![DB Tables](images/M1.g.png)

Selecting only the tables the agent needs reduces ambiguity. The other tables in `db_retail` aren't used in this track.

---

## 2. Test Mark's answers

### a. In the chat pane, ask the following questions

![Test Mark](images/M2.a.png)

i. What are the orders from Omar Bennett?
ii. What are the orders from Omar Bennett and the detailed products for each order?
iii. What are the orders for customer CID-069 between July 1, 2019 and May 31, 2021?
iv. What are the historical trends across all my data?
v. What are the product details for order F100241?

![Test Mark](images/M2.a.v.png)

For each answer, expand the steps to see the generated SQL. Note which questions fail or return incomplete products. The most common gap is question v: `F100241` is an **OrderNumber**, while the tables join on the internal **OrderId** (a UUID). Without guidance, the agent may filter on the wrong column.

> [!NOTE]
> Data agent responses are capped at 25 rows and 25 columns. Broad questions such as iv summarize rather than list every row.

If you don't get the products for order `F100241`, continue with step 3.

---

## 3. Improve Mark with instructions and examples

A Fabric data agent has three configuration layers. Use each one for what it's designed for:

| Layer | Scope | Use it for |
|---|---|---|
| **Agent instructions** | Whole agent | Role, scope, source routing, tone, response format |
| **Data source instructions** | One data source | Joins, key columns, column meaning, filters for that source |
| **Example queries** | One data source | Question-to-SQL pairs the agent can reuse (up to 100 per source) |

For more information, see [Data agent configurations](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-configurations).

![Agent Instructions empty](images/M2.b.png)

### a. Add agent instructions

Select **Agent instructions** in the ribbon and paste:

```markdown
# Role
You are Mark, the Contoso Retail facts agent. You return exact, traceable transactional facts about customers, orders, order lines, and products. You don't speculate or interpret beyond the data.

# Scope
- Answer only from the db_retail SQL database.
- If a question can't be answered from customer, orders, orderline, or product, say so.

# Response rules
- Use tables for multi-row results.
- State the filters you applied (customer, order number, dates).
- When a question is ambiguous (for example, no order is specified), return a reasonable summary and explain the criteria used.
- Never invent customers, orders, products, or values. If no rows match, say so clearly.
```

### b. Add data source instructions

Open the `db_retail` source in the explorer, select **Data source instructions**, and paste:

```markdown
## Tables
- customer: one row per customer. Key: CustomerId (for example CID-069). Name is FirstName + LastName.
- orders: order header. Key: OrderId (internal UUID). Business identifier shown to users: OrderNumber (for example F100241). Foreign key: CustomerId.
- orderline: one row per product line in an order. Key: OrderId + OrderLineNumber. Foreign keys: OrderId -> orders, ProductID -> product.
- product: product catalog. Key: ProductID (integer).

## Mandatory joins
- customer.CustomerId = orders.CustomerId (one customer, many orders)
- orders.OrderId = orderline.OrderId (one order, many lines)
- orderline.ProductID = product.ProductID (each line references one product)

When a question involves customers, orders, and products, traverse the full chain:
customer -> orders -> orderline -> product

## Identifier rules
- Values that look like F100241 are OrderNumber values. Filter orders.OrderNumber, then join to orderline on OrderId. Never compare an OrderNumber with OrderId.
- Values that look like CID-069 are CustomerId values.
- To find a customer by name, filter FirstName and LastName.

## Reasoning rules
- Questions about what a customer bought use orderline as the central table, filtered by customer through orders.
- Order-level money uses orders.SubTotal, orders.TaxAmount, orders.OrderTotal. Line-level money uses orderline.LineTotal, DiscountAmount, TaxAmount. Don't mix the two grains in one total.
```

### c. Add example queries

In the same data source, select **Example queries** and add these question-and-SQL pairs:

| Question | SQL |
|---|---|
| What are the product details for order F100241? | `SELECT o.OrderNumber, l.OrderLineNumber, p.ProductName, p.BrandName, p.CategoryName, l.Quantity, l.UnitPrice, l.LineTotal, l.DiscountAmount, l.TaxAmount FROM dbo.orders o JOIN dbo.orderline l ON l.OrderId = o.OrderId JOIN dbo.product p ON p.ProductID = l.ProductID WHERE o.OrderNumber = 'F100241' ORDER BY l.OrderLineNumber;` |
| What are the orders from Omar Bennett? | `SELECT o.OrderNumber, o.OrderDate, o.OrderStatus, o.OrderTotal FROM dbo.customer c JOIN dbo.orders o ON o.CustomerId = c.CustomerId WHERE c.FirstName = 'Omar' AND c.LastName = 'Bennett' ORDER BY o.OrderDate;` |

Run each SQL statement in the `db_retail` query editor first and confirm that it returns rows.

![Agent Instructions](images/M2.b.3.png)

### d. Test again

1. Clear the chat.
2. Confirm that you want to clear the chat.

![Clear chat](images/M2.b.4.png)

3. Ask the question that failed before: **What are the product details for order F100241?**

![New chat session](images/M2.b.5.png)

4. Ask a variation the example doesn't cover literally, such as **Which products and quantities were in order F100002?**, to check that the agent generalizes the pattern instead of copying it.

---

## 4. Publish the data agent

### a. Select **Publish**

![Publish Agent](images/M3.a.png)

### b. Add a description

Write the description for the agents that will call Mark later (Copilot Studio in Lab 09), for example:

`Returns exact Contoso Retail transactional facts (customers, orders, order lines, products, amounts, dates) from the db_retail SQL database.`

### c. Optionally publish to the Agent Store in Microsoft 365 Copilot

![Publish Agent](images/M3.c.png)

---

## 5. Preserve Mark v1 as the SQL baseline

Don't replace Mark's `db_retail` source. Lab 03 creates a separate agent named **Mark v2** over the `sm_retail` semantic model, and Lab 04 creates **Mark IQ** over the Fabric IQ ontology. Keeping all versions lets you run the same questions and compare raw SQL, governed DAX measures, and ontology-grounded answers.

## Mission Complete

Mark v1 answers questions from raw tables, guided by instructions and examples you wrote by hand. Notice how much business knowledge (keys, joins, identifier formats, grain) you had to put in prompts. Fabric IQ moves that knowledge into governed, reusable artifacts.

Continue to [Lab 03 - Mark v2 with a semantic model](lab03-mark-v2-semantic-model.en.md).
