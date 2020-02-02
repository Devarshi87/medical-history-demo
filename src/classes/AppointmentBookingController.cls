public class AppointmentBookingController {
    
    public Opportunity newOppObj{get;set;}
    public OpportunitylineItem oppline;
    public Patient__c newPatientObj{get;set;}
    public String serviceSelected{get;set;}
    public string patientType{get;set;}
    public map<string, pricebookentry> servicePricemap{get;set;}
    public map<string, contact> physicianMap{get;set;}
    public String searchEmailString{get;set;}
    
    public String selectedPhysician{get;set;}

    public Event latestEvent{get;set;}
    
    public AppointmentBookingController(){
        newPatientObj = new Patient__c();
    	newOppObj =  new Opportunity();
        oppline = new OpportunityLineitem();
        serviceSelected ='';
        servicePricemap = new map<string, pricebookentry>();
        patientType = 'none';
        searchEmailString='';
        selectedPhysician='';
        physicianMap = new map<string, contact>();

        //latestEvent = new Event();
    }
    
    public void searchPatient(){
        
         list<Patient__c> patientlist = [select id, name,Patient_email__c,patient_phone__c from Patient__c where patient_email__c =: searchEmailString limit 1];

        //newOppObj = [select id, Name, Patient_email__c,Assigned_Physician__c, patient_phone__c,CloseDate from opportunity ];
        patientType ='new';
        If(patientlist.isEmpty()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Not a existing Patient. Please create new one.'));
        }
        else{
            newPatientObj = patientlist [0];
        }
        
        //system.debug('=newOppObj====>'+newOppObj);
    }

    public List<Event> getpatientEventhistory(){
        List<Event> temList = new List<Event>();
        temList = [select Id, Subject,Status__c, isAllDayEvent,Google_Cal_Event_Id__c,WhoId,WhatId, StartDateTime,Opportunity__c, EndDateTime from Event where WhatId = : newPatientObj.id order by CreatedDate desc];
        return temList;
    }
    public void deleteCaleEvent(){
        String eventId = ApexPages.currentPage().getParameters().get('cancelEvent');
        Event eventToCancel  = fetchEvent(eventId);
        Contact cont = fetchContact(eventToCancel.WhoId);
        Patient__c patient= fetchPatient(eventToCancel.WhatId);
        system.debug('event to cancel =====> '+ eventToCancel);
        if(cont!=null && eventToCancel!=null){

            try{
                if(cont.access_token__c!=null && cont.access_token__c!='' && eventToCancel.Google_Cal_Event_Id__c !=null && eventToCancel.Google_Cal_Event_Id__c!=''){
                    if(cont.token_expired__c){
                        cont = CalendarInvitationUtility.doRefreshToken(cont);

                    }
                    CalendarInvitationUtility.deleteCalendarEvent(cont,eventToCancel.Google_Cal_Event_Id__c);
                    system.debug('event to cancel success =====> '+ eventToCancel);


                }
                else{
                    List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                    List<String> sendTo = new List<String>{cont.Email , patient.Patient_Email__c};
                    String bodytext = 'Hi '+ cont.FirstName+ ',\n Your appointment with date '+eventToCancel.StartDateTime+' has been cancelled. Please get in touch with the medical clinic support if you didn\'t do it.';
                    mail.setSaveAsActivity(false);
                    mail.setSubject('Appointment cancellation confirmation');
                    mail.setPlainTextBody(bodytext);
                    mail.setToAddresses(sendTo);
                    mail.setReplyTo('noreply@demo-med.com');
                    mail.setSenderDisplayName('Medical Clinic');


                    mails.add(mail);

                    Messaging.sendEmail(mails);
                }

                eventToCancel.status__c = 'Cancelled';

                update  eventToCancel;
                if(eventToCancel.Opportunity__c !=null){
                    eventToCancel.Opportunity__r.Stagename = 'Closed Lost';

                    update eventToCancel.Opportunity__r;
                }

            }catch(Exception ex){
                system.debug('====Event cancellation failed===>' + ex.getLineNumber()+ex.getMessage());
            }


            update cont;
        }


    }

    public Event getEventObj(){
        String eventId = ApexPages.currentPage().getParameters().get('createdEventId');
        if(!String.isBlank(eventId)){
            latestEvent = new Event();
            latestEvent = fetchEvent(eventId);
            return latestEvent;
        }

        return null;
    }

    public event fetchEvent(String eventId){
        if(!String.isBlank(eventId)){
            Event temp = new Event();
            temp = [Select Id,StartDateTime,EndDateTime,Google_Cal_Event_Id__c,Whoid,Whatid,Subject,Opportunity__r.id,Opportunity__c from  Event where id = : eventId];

            return temp;

        }
        return null;
    }

    public void sendCalendarInvite(){
        try{

            Contact cont = fetchContact(latestEvent.WhoId);

            system.debug('==physicianEmail====>'+latestEvent);
            if(cont!=null && latestEvent!=null){
                //Contact cont = physicianMap.get(latestEvent.WhoId);
                if(cont.access_token__c!=null && cont.access_token__c!=''){
                    if(cont.token_expired__c){
                        cont = CalendarInvitationUtility.doRefreshToken(cont);

                    }
                    CalendarInvitationUtility.doCreateNewCalendarEvent(cont, newPatientObj.Patient_Email__c, latestEvent);
                }
                else if(cont.Email!=null){
                    system.debug('==physicianEmail====>'+cont.Email);
                    CalendarInvitationUtility.sendinvite(cont.Email, newPatientObj.Patient_Email__c, latestEvent);
                }

                update cont;
            }
            else{
                system.debug('==physicianEmail====>'+latestEvent);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Physician Email is missing!'));
            }
        }catch(exception ex){
            system.debug('===email sending failed==>'+ex.getLineNumber()+ex.getMessage());
        }


    }

    public void createCalendarInviteForPhysician(Contact physician){
        if(physician != null){

        }
    }

    public contact fetchContact(String conId){
        return [Select id,FirstName, Name,Email,access_token__c,Refresh_Token__c,Expire_In__c,token_expired__c  from Contact where id =: conId  ];
    }

    public Patient__c fetchPatient(String patientid){
        return [select id, name,Patient_email__c,patient_phone__c from Patient__c where id =: patientid limit 1];
    }


    public list<selectOption> getProductList(){
        list<selectOption> options = new list<selectoption>();
        options.add(new SelectOption('', '--Select Department--' ));
        for(pricebookEntry prc: [Select id, product2.name , unitprice from pricebookentry where pricebook2.name='Standard Price book']){
            options.add(new SelectOption(String.valueOf(prc.id), prc.product2.name ));
            servicePricemap.put(prc.id , prc);
        }
        return options;
    }
    
    public list<selectOption> getPhysicianList(){
        list<selectOption> options = new list<selectoption>();
        //physicianMap = new map<string, contact>();
        string physicianDept = '';

        if(servicePricemap.containsKey(serviceSelected)){
            physicianDept = servicePricemap.get(serviceSelected).product2.Id;
        }

        options.add(new SelectOption('', '--Select Physician--' ));
        for(Contact con: [Select id, Name,Email,access_token__c,Refresh_Token__c,Expire_In__c,token_expired__c  from Contact where Specialization__c =: physicianDept  ]){
            options.add(new SelectOption(String.valueOf(con.id), con.name ));
            physicianMap.put(con.Id,con);
        }
        return options;
    }
    
    public void saveAction(){
        
        try{
            upsert newPatientObj;
        }
        catch(Exception ex){
            system.debug('exception at' + ex.getLineNumber() +ex.getMessage());
        }
    }
    
    public void addProductService(){
        
        if(newPatientObj.id !=null && servicePricemap.containsKey(serviceSelected)){
            //newOppObj =  new Opportunity();
            newOppObj.Name = newPatientObj.Name + '--' + servicePricemap.get(serviceSelected).Product2.Name;
            newOppObj.StageName = 'Qualification';
            newOppObj.closedate = system.today();
            newOppObj.Patient__c = newPatientObj.id;
            try{
                upsert newOppobj;
            }
            catch(Exception ex){
                system.debug('exception at' + ex.getLineNumber() +ex.getMessage());
            }
            if(oppline.id != null){
                try{
                    delete oppline;
                }
                catch(Exception ex){
                    system.debug('===> deletion of the oppline failed===>' + ex.getLineNumber() + ex.getMessage());
                }

            }
            oppline = new OpportunityLineitem();
            oppline.OpportunityId = newOppObj.id;
            oppline.PricebookEntryId = servicePricemap.get(serviceSelected).id;
            oppline.Quantity = 1;
            oppline.unitprice = servicePricemap.get(serviceSelected).unitprice;
            
            insert oppline;
        }
        
    }
    public void updateOpp(){

        if(newOppObj.id!=null){
            newOppObj.Assigned_Physician__c = selectedPhysician;

            try{
                update newOppObj;
            }
            catch (Exception ex){
                system.debug('===physician update faile'+ ex.getLineNumber()+ex.getMessage());
            }

        }

    }



    public decimal getProductObj(){
        system.debug('====>'+serviceSelected);
        if(servicePricemap.containsKey(serviceSelected) && servicePricemap.get(serviceSelected)!=null){


                return servicePricemap.get(serviceSelected).unitprice;


        }
            return 0.00;
            
    }
    
    

}