public with sharing class OrderService {

    public static void generateInvoices(Set<Id> orderIds) {
        // Invoice generation from given orders
        List<Invoice__c> invoices = new List<Invoice__c>();
        List<Order> orders = 
            [select Id, TotalAmount, Invoiced__c, EffectiveDate, Name from Order 
                where Id in :orderIds and Invoiced__c != true];
        for(Order order : orders) {
            produceSomeExceptions(order.Name, order.EffectiveDate);
            Invoice__c invoice = new Invoice__c();
            invoice.DueDate__c = System.today().addDays(30);
            invoice.Paid__c = false;
            invoice.Order__c = order.Id;
            invoice.Amount__c = order.TotalAmount;
            invoices.add(invoice);
            order.Invoiced__c = true;            
        }
        insert invoices;
        update orders;
    }

    // Produce some exceptions, some catchable, some not...
    private static void produceSomeExceptions(String orderName, Date orderDate) {
        if(orderDate != System.today()) { return; } 
        switch on orderName {
           when 'Ref:100' {
               // Standard exception
               throw new InvoiceGenerationException('Order Ref:100 is invalid.');
           }
           when 'Ref:300' {
               // Divide by zero!
               Integer newAmount = 20 / 0;
           }
           when 'Ref:500' {
                // Limits exception
                for(Integer idx=0; idx<201; idx++) {
                    Order order = [select Id from Order limit 1];
                }
           }
        }
    }

    public static void emitGenerateInvoiceEvents() {
        List<GenerateInvoice__e> events = new List<GenerateInvoice__e>();
        for(Order order : [select Id from Order where Invoiced__c != true order by OrderNumber asc]) {
            events.add(new GenerateInvoice__e(OrderId__c = order.Id));
        }
        EventBus.publish(events);        
    }
    
    public class InvoiceGenerationException extends Exception {} 
}
