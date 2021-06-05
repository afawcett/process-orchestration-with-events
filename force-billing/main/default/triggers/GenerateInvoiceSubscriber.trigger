trigger GenerateInvoiceSubscriber on GenerateInvoice__e (after insert) {

    // Emit telemetry
    EventBus.publish(
        new SubscriberTelemetry__e(
            Topic__c = 'GenerateInvoice__e', 
            ApexTrigger__c = 'GenerateInvoiceSubscriber',
            Position__c = [select Position from EventBusSubscriber where Topic = 'GenerateInvoice__e'][0].Position,
            BatchSize__c = Trigger.new.size(),
            Retries__c = EventBus.TriggerContext.currentContext().retries,
            LastError__c = EventBus.TriggerContext.currentContext().lastError));

    // Determine number overall order lines to process vs maximum within limits (could be config)
    Integer maxLines = 40000;
    Set<Id> orderIds = new Set<Id>();
    for (GenerateInvoice__e event : Trigger.New) {
        orderIds.add(event.OrderId__c);
    }
    Map<Id, Integer> lineCountByOrderId = 
        new OrdersSelector().selectLineCountById(orderIds);

    // Bulkify events passed to the OrderService
    orderIds = new Set<Id>();
    Integer lineCount = 0;
    for (GenerateInvoice__e event : Trigger.New) {
        orderIds.add(event.OrderId__c);
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(event.ReplayId);
        lineCount = lineCount + lineCountByOrderId.get(event.OrderId__c);
        if(lineCount>maxLines) { 
            break;
        }
    }

    // Invoke OrderService, support retries
    try {
        OrderService.generateInvoices(orderIds);
    } catch (Exception e) {
        // Only retry so many times, before giving up (thus avoid disabling the trigger)
        if (EventBus.TriggerContext.currentContext().retries < 6) {
            throw new EventBus.RetryableException(e.getMessage());
        }
        // In this case its ok to let the events drain away... 
        //   since new events for unprocessed Orders can always be re-generated
    }    
}