# Apex Process Orchestration and Monitoring with Platform Events (Cactusforce Keynote Demo)

Related [blog post](https://andyinthecloud.com/2020/04/02/apex-process-orchestration-and-monitoring-with-platform-events/)

Deploy Setup
------------
Run the following commands to deploy:-

```
sfdc force:source:push
sfdx force:user:permset:assign --permsetname Cactusforce
sfdx force:user:permset:assign --permsetname Billing
sfdx force:user:permset:assign --permsetname brf_BatchRetryFramework
```

Data Setup
----------

```
sfdx force:apex:execute
```

Run the following Apex code block to configure test data.

```
delete [select Id from Invoice__c];
delete [select Id from Order];
delete [select Id from Account];
delete [select Id from brf_BatchApexErrorLog__c];
Account orderAccount = new Account();
orderAccount.Name = 'Great customer!';
insert orderAccount;
List<Order> orders = new List<Order>();
for(Integer orderIdx = 0; orderIdx < 1000; orderIdx++) {
    Order order = new Order();
    order.Name = 'Ref:'+orderIdx;
    order.Status = 'Draft';
    order.EffectiveDate = System.today();
    order.AccountId = orderAccount.Id;
    order.NumberOfLines__c = Integer.valueof((Math.random() * 1000));
    orders.add(order);
}
insert orders;
```

Demo Steps - via Batch Apex
----------------------------

Perform the following steps to try out the framework with the sample app (included):-

1. Open the **Billing** app
2. Click the **Orders** tab and select the **All** list view
3. Click the **Invoice Generation** button to start the job
4. Open the **Failed Jobs** utlity bar and click **Refresh** button to see logged failures
5. Use the **Orders** tab and **Bad Orders** list view to review bad records and delete one or edit **Order Start Date** to another date
6. Open the **Failed Jobs** utility bar and click **Retry** action on the failed job
7. Click the **Refresh** button to review remaining errors, repeat steps 5-7 until all clear!

Demo Steps - via Platform Events - One at time
----------------------------------------------

1. Open the **Billing** app
2. Click the **Orders** tab and select the **All** list view
3. Run the following Apex code to process one order at a time
4. Refresh the list view to and sort by Order Number, noting the Invoiced status field

```
List<GenerateInvoice__e> events = new List<GenerateInvoice__e>();
for(Order order : 
  [select Id from Order where Invoiced__c != true order by OrderNumber asc limit 1]) {
    events.add(new GenerateInvoice__e(OrderId__c = order.Id));
}
EventBus.publish(events);
```

Demo Steps - via Platform Events - Mass
---------------------------------------

1. Open the **Billing** app
2. Click the **Orders** tab and select the **All** list view
3. Run the following Apex code to process one order at a time
4. Refresh the list view to and sort by Order Number, noting the Invoiced status field

```
List<GenerateInvoice__e> events = new List<GenerateInvoice__e>();
for(Order order : 
  [select Id from Order where Invoiced__c != true order by OrderNumber asc]) {
    events.add(new GenerateInvoice__e(OrderId__c = order.Id));
}
EventBus.publish(events);
```

Misc Commands
-------------

Use this to query EventBusSubscriber status

```
sfdx force:data:soql:query -q "select LastError, Name, Position, Retries, Status, Tip, Topic, Type from EventBusSubscriber where Topic = 'GenerateInvoice__e'"
```

Generate a password in order to use Workbench and display events.

```
sfdx force:user:password:generate
```