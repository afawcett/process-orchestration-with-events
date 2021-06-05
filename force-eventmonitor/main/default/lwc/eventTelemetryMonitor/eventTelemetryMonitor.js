import { LightningElement, track, api} from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

const columns = [
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date',
        typeAttributes:{
            year: "numeric",
            month: "long",
            day: "2-digit",
            hour: "2-digit",
            minute: "2-digit"
        }    
    },    
    { label: 'Position', fieldName: 'Position__c', type: 'number' },
    { label: 'Apex Trigger', fieldName: 'ApexTrigger__c' },
    { label: 'Batch Size', fieldName: 'BatchSize__c', type: 'number' },
    { label: 'Last Error', fieldName: 'LastError__c' },
    { label: 'Retries', fieldName: 'Retries__c', type: 'number' },
    { label: 'Topic', fieldName: 'Topic__c' },
];

export default class EventTelemetryMonnitor extends LightningElement {
    @api eventData = [];
    @track columns = columns;
    @track channelName = '/event/SubscriberTelemetry__e';
    @track isSubscribeDisabled = false;
    @track isUnsubscribeDisabled = !this.isSubscribeDisabled;

    subscription = {};

    connectedCallback() {
        this.handleSubscribe();
    }    

    // Tracks changes to channelName text field
    handleChannelName(event) {
        this.channelName = event.target.value;
    }

    // Handles subscribe button click
    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        var messageCallback = function(response) {
            console.log('New message received : ', JSON.stringify(response));
            const rows = this.eventData.slice();
            const row = response.data.payload;
            row['ReplayId'] = response.data.event.replayId;
            rows.unshift(row);
            this.eventData = rows;
            // Response contains the payload of the new message received
        };
        messageCallback = messageCallback.bind(this);

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on successful subscribe call
            console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
            this.subscription = response;
            this.toggleSubscribeButton(true);
        });
    }

    // Handles unsubscribe button click
    handleUnsubscribe() {
        this.toggleSubscribeButton(false);

        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    toggleSubscribeButton(enableSubscribe) {
        this.isSubscribeDisabled = enableSubscribe;
        this.isUnsubscribeDisabled = !enableSubscribe;
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }
}