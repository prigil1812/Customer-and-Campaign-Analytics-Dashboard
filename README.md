# Customer-and-Campaign-Analytics-Dashboard
An interactive 3-page Power BI report that analyses 2,240 customers: what they buy, how they respond to six marketing campaigns, and which segments are worth targeting next. It includes an RFM (Recency, Frequency, Monetary) segmentation.

Business question: Who are our best customers, which of them respond to campaigns, and where should the next marketing dollar go?

Dashboard preview
<img width="888" height="499" alt="image" src="https://github.com/user-attachments/assets/3491b2e4-f30a-4d0e-b634-99b92f19634f" />
<img width="887" height="501" alt="image" src="https://github.com/user-attachments/assets/cf7f8e8d-f17f-4373-9193-e6b77147cd53" />
<img width="889" height="494" alt="image" src="https://github.com/user-attachments/assets/c5c95288-b809-4bb9-b164-0a377ec22f2d" />

What the dashboard answers
Page	Questions answered
1. Customer and Spend Overview	How big and engaged is the customer base? What do customers buy, and where? Which age groups spend most? When did customers join?
2. Campaign Performance	Which campaigns worked and which flopped? Who responds (income, education, recency, household)? Do the same people respond every time?
3. Customer Segments (RFM)	How is the base split into Champions, At-Risk High Value, Promising and Dormant? How much revenue sits in a few customers? What does each segment buy? Who should we win back first?
Key insights
Total spend: 1,356,988 across 2,240 customers (about 606 per customer; the source does not state a currency).
Product mix: wines make up about half of all spend and meat about 28%, so roughly 78% comes from two categories.
Channels: store accounts for about 46% of purchases, web about 33% and catalog about 21%.
Campaign results: acceptance was about 6.4%, 1.3%, 7.3%, 7.5% and 7.3% for campaigns 1 to 5, then 14.9% for the last campaign. Campaign 2 was clearly the weakest.
Responders: 609 customers (27.2%) accepted at least one campaign.
Who responds: the last campaign reached about 28% of high-income customers versus roughly 10 to 12% for low and middle income. PhD holders responded at about 21% and Basic education at about 4%.
Households: customers without children had a responder rate of about 45%, versus about 20% for those with children.
Recency: customers who bought in the last 30 days responded at about 24%, against about 9% for those inactive 60+ days.
Concentration: the Champions segment accounts for about 43% of total spend.

These are patterns in the data, not proof of cause. Income, household size and spend are linked to each other.

Dataset
Source: Customer Personality Analysis on Kaggle (marketing campaign data, tab-delimited).
Size: 2,240 customers; enrollment dates from July 2012 to June 2014.
Fields: demographics, income, household, spend by product category, purchases by channel, web visits, recency, and acceptance of six campaigns.
Data cleaning and transformation (Power Query)
Issue found	Action
Tab-delimited file with day-month-year dates	Set the delimiter and parsed dates with the en-GB culture
24 missing incomes	Kept blank (not guessed) and grouped as "Unknown" income band
One income of 666,666 (next highest about 162K)	Treated as an outlier and set to blank
3 impossible birth years (1893 to 1900)	Set to blank; age group becomes "Unknown"
Marital status labels "Alone", "Absurd", "YOLO"	Alone merged into Single; Absurd and YOLO grouped as Other
Education labels "Graduation" and "2n Cycle"	Renamed to Graduate; 2n Cycle treated as Master level (assumption)
Two constant columns (Z_CostContact, Z_Revenue) with no documented meaning	Dropped
3 customers with more discount purchases than total purchases	Flagged and excluded from the discount measure

Derived fields: age and age group, income band, tenure, children count, total spend, total purchases, campaigns accepted, and customer flags.

Data model

Star schema built by unpivoting wide columns into long fact tables:

DimCustomer: one row per customer (demographics, segments, totals)
FactSpend: customer x product category
FactChannel: customer x purchase channel (store, web, catalog)
FactCampaign: customer x campaign (6 campaigns)
DimDate: calendar over the enrollment period
DAX highlights (25+ measures and 5 calculated columns)
Customer and spend: Customers, Total Spend, Avg Spend per Customer, Spend per Purchase, Category Share %
Campaigns: Acceptance Rate %, Last Campaign Response %, Responder Rate %, Repeat Responders, Response Lift
Channels and engagement: Channel Mix %, Deal Purchase %, Avg Web Visits per Month
RFM segmentation: R, F and M scores (quartile-based, 1 to 4) and a segment label:
Champions: recent and high frequency/spend
At-Risk High Value: high frequency/spend but not recent
Promising: recent but lower frequency/spend
Dormant: neither recent nor high value

Full code: scripts/02_DAX_Marketing.dax

Tools

Power BI Desktop, Power Query (M), DAX

Limitations and next steps
Single snapshot from one business; currency is not stated
Campaigns have no dates, offer types or cost, so response rate and lift are measured but ROI cannot be calculated
The data does not explain why the last campaign performed better
Next: add campaign cost data for ROI, build a response-prediction model, and run holdout tests for future campaigns
