/**
 * Example job demonstrating the batch apex retry framework
 **/
public class InvoiceGenerationJob 
    implements Database.Batchable<SObject>, brf_BatchableErrorHandler
{
    public List<Order> start(Database.BatchableContext ctx) {
        return new OrdersSelector().selectThisWeeksOrders();
    }

    public void execute(Database.BatchableContext ctx, List<SObject> scope) {
        OrderService.generateInvoices(new Map<Id, SObject>(scope).keySet()); 
    }
    
    public void finish(Database.BatchableContext ctx) { }

    public void handleErrors(brf_BatchableError error) {
        // Update the effected orders with the error for further review
        Set<Id> orderIds = new Set<Id>(); 
        for(String orderId : error.JobScope.split(',')) { orderIds.add(orderId); }
        List<Order> orders = new OrdersSelector().selectById(orderIds);
        for(Order order : orders) {
            order.InvoiceGenerationError__c = error.Id;
        }
        update orders; 
    }

    /**
     * InvoiceGenerationJob.run();
     **/
    public static Id run() {
        // Chunk size of 200 forces 5 batches given the sample data used in this example
        return Database.executeBatch(new InvoiceGenerationJob(), 200);
    }

    public class InvoiceGenerationException extends Exception {} 
}
