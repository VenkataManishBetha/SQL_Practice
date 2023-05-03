--SELECT * FROM dbo.Sales

-- 1. What is the total amount each customer spent at the restaurant?

SELECT Customer_id,SUM(Price) AS Total_Amount 
FROM dbo.Menu  Inner Join dbo.Sales
ON Sales.Product_Id = Menu.Product_Id
GROUP BY Customer_Id;

-- 2. How many days has each customer visited the restaurant?

SELECT Customer_id, COUNT(DISTINCT Order_Date) FROM dbo.Sales
GROUP BY Customer_Id

-- 3. What was the first item from the menu purchased by each customer?

WITH CTE AS (
SELECT Customer_id, Product_Name, RANK() OVER(PARTITION BY Customer_Id ORDER BY Order_Date) RANK
FROM Sales INNER JOIN Menu
ON Sales.Product_Id = Menu.Product_Id
)

SELECT Customer_Id, Product_Name FROM CTE
WHERE RANK = 1

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

WITH CTE AS (SELECT Product_Name, COUNT(Sales.Product_Id) AS Most_Purchased
FROM Sales INNER JOIN Menu
on Sales.Product_Id = Menu.Product_Id
GROUP BY Sales.Product_Id, Product_Name
)

SELECT TOP 1 * FROM CTE
ORDER BY Most_Purchased DESC

--5. Which item was the most popular for each customer?

WITH CTE AS
( SELECT Customer_Id, Product_Name, RANK() OVER(PARTITION BY Customer_Id ORDER BY COUNT(Sales.Product_Id)DESC) AS RANK
FROM Sales INNER JOIN Menu
ON Sales.Product_Id = Menu.Product_Id
GROUP BY Sales.Product_Id, Customer_Id, Product_Name
)

SELECT Customer_Id, Product_Name FROM CTE
WHERE RANK = 1

--6. Which item was purchased first by the customer after they became a member?

WITH CTE AS
( SELECT Sales.Customer_Id, Menu.Product_Name, Sales.Order_Date, RANK() OVER (PARTITION BY Sales.Customer_Id ORDER BY Sales.Order_Date) AS RANK
FROM Sales INNER JOIN Menu
ON Sales.Product_Id = Menu.Product_Id
INNER JOIN Members
ON Sales.Customer_Id = Members.Customer_Id
WHERE Sales.Order_Date >= Members.Join_Date
GROUP BY Sales.Customer_Id, Menu.Product_Name, Sales.Order_Date
)

SELECT Customer_Id, Product_Name FROM CTE
WHERE RANK = 1

--7. Which item was purchased just before the customer became a member?

WITH CTE AS
( SELECT Sales.Customer_Id, Menu.Product_Name, Sales.Order_Date, RANK() OVER (PARTITION BY Sales.Customer_Id ORDER BY Sales.Order_Date DESC) AS RANK
FROM Sales INNER JOIN Menu
ON Sales.Product_Id = Menu.Product_Id
INNER JOIN Members
ON Sales.Customer_Id = Members.Customer_Id
WHERE Sales.Order_Date < Members.Join_Date
GROUP BY Sales.Customer_Id, Menu.Product_Name, Sales.Order_Date
)

SELECT Customer_Id, Product_Name FROM CTE
WHERE RANK = 1

--8. What is the total items and amount spent for each member before they became a member?

SELECT Sales.Customer_Id, COUNT(Menu.Product_Name) AS Total_Items, SUM(Menu.Price) AS Total_Amount
FROM Sales INNER JOIN Menu
ON Sales.Product_Id = Menu.Product_Id
INNER JOIN Members
ON Sales.Customer_Id = Members.Customer_Id
WHERE Sales.Order_Date < Members.Join_Date
GROUP BY Sales.Customer_Id

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT Sales.Customer_Id,
SUM(
CASE
    WHEN Sales.Product_Id = 1 THEN Menu.Price*20
    ELSE Menu.Price*10
END)
FROM Sales INNER JOIN Menu ON Sales.Product_Id = Menu.Product_Id
GROUP BY Sales.Customer_Id


--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
-- not just sushi - how many points do customer A and B have at the end of January?


SELECT Sales.Customer_Id,
SUM(
CASE
    WHEN Sales.Order_Date BETWEEN Members.Join_Date AND DATEADD(DAY,6,Join_Date) THEN Menu.Price*10*2 
    WHEN Sales.Order_Date <= '2021-01-31' THEN Menu.Price*10
END) AS Points
FROM Sales INNER JOIN Menu ON Sales.Product_Id = Menu.Product_Id
INNER JOIN Members ON Sales.Customer_Id = Members.Customer_Id
GROUP BY Sales.Customer_Id, Sales.Order_Date, Members.Join_Date
