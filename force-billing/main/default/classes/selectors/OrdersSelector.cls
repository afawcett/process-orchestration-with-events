public inherited sharing class OrdersSelector {

    public List<Order> selectById(Set<Id> orderIds) {
        return [select Id, NumberOfLines__c from Order where Id in :orderIds];
    }

    public List<Order> selectThisWeeksOrders() {
        return [select Id from Order 
                where EffectiveDate = THIS_WEEK and Invoiced__c != true
                order by Name];
    }

    public Map<Id, Integer> selectLineCountById(Set<Id> orderIds) {
        Map<Id, Integer> lineCountByOrderId = new Map<Id, Integer>();
        for(Order order : selectById(orderIds)) {
            lineCountByOrderId.put(order.Id, Integer.valueOf(order.NumberOfLines__c));
        }
        return lineCountByOrderId;
    }
}
