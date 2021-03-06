public class CalendarScheduleController {
    public string eventsJSON {get;set;}
    
    public Event newEvent{get;set;}
    
    //The calendar plugin is expecting dates is a certain format. We can use this string to get it formated correctly
    static String dtFormat = 'EEE, d MMM yyyy HH:mm:ss z';
    
    public CalendarScheduleController(){
        newEvent = new Event();
    }
    
    @RemoteAction
    public static string eventdata( string relatedPhysicianid){
        calEvent[] events = new calEvent[]{};
            List<Event> eventList = new List<Event>();
        if(relatedPhysicianid!=null && relatedPhysicianid !=''){
            eventList = [select Id, Subject, isAllDayEvent,Google_Cal_Event_Id__c, StartDateTime,Opportunity__c, EndDateTime from Event where EndDate > today and whoid=:relatedPhysicianid];
        }
        else{
            eventList = [select Id, Subject, isAllDayEvent,Google_Cal_Event_Id__c, StartDateTime,Opportunity__c, EndDateTime from Event where EndDate > today and whoid!=null and whatid!=null];
            
        }
        for(Event evnt: eventList){
            DateTime startDT = evnt.StartDateTime;
            DateTime endDT = evnt.EndDateTime;
            system.debug('===evnt.StartDateTime==>'+evnt.StartDateTime+'==startDT===?'+startDT);
            calEvent myEvent = new calEvent();
            myEvent.eventid = evnt.Id;
            myEvent.title = evnt.Subject;
            myEvent.allDay = evnt.isAllDayEvent;
            myEvent.startString = startDT.format(dtFormat);
            myEvent.endString = endDT.format(dtFormat);
            //myEvent.url = '/' + evnt.Id;

            myEvent.className = 'event-personal';
            events.add(myEvent);
            
            system.debug('===evnt.myEvent.startString==>'+myEvent.startString);
        }
        
        string jsonEvents = JSON.serialize(events);
        jsonEvents = jsonEvents.replace('startString','start');
        jsonEvents = jsonEvents.replace('endString','end');
        
        return jsonEvents;
    }
    
    @RemoteAction
    public static String createOrUpdateEvents(String calendarEvent, string relatedPhysicianid, String relatedPatientID,String oppId) {
        
        Event eventObject = ((Event) JSON.deserialize(calendarEvent, Event.class));
        if(!String.isBlank(relatedPhysicianid) && !String.isBlank(relatedPatientID)){
            
            
            system.debug('eventObjt===>' + eventObject);
            eventObject.whoid = relatedPhysicianid;
            eventObject.whatid = relatedPatientID;
            eventObject.Opportunity__c = oppId;
            eventObject.Status__c = 'Upcoming';
            upsert eventObject;
            system.debug('eventObjt=after==>' + eventObject);
            
        }
       
            return JSON.serialize(eventObject);
        
    }

     public Event getEventObjCal(){
         String eventId = ApexPages.currentPage().getParameters().get('viewEvent');

         if(!String.isBlank(eventId)){
             newEvent = new Event();
             newEvent = [Select Id,StartDateTime,EndDateTime,Google_Cal_Event_Id__c,Whoid,Whatid,Subject,Status__c from  Event where id = : eventId];

             return newEvent;

         }
         return null;
     }


    
    
    // Class to hold calendar event data
    public class calEvent {
        public String eventid{get;set;}
        public String title {get;set;}
        public Boolean allDay {get;set;}
        public String startString {get;set;}
        public String endString {get;set;}
        // public String url {get;set;}
        public String className {get;set;}
    }
}