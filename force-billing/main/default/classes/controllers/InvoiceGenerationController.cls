public with sharing class InvoiceGenerationController {

    private ApexPages.StandardSetController controller;

    public InvoiceGenerationController(ApexPages.StandardSetController controller) {
        this.controller = controller;
    }

    public PageReference runJob() {
        InvoiceGenerationJob.run();
        return controller.cancel();
    }

    public PageReference emitEvents() {
        OrderService.emitGenerateInvoiceEvents();
        return controller.cancel();
    }

}
