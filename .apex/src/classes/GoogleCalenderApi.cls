public class GoogleCalenderApi {
    
    public static Boolean AuthorizationSucces { get; set; }
    
    // Your CLient ID Here
    public Final static String consumerKey='717895365078-k5d9oj0q274fk7pmr7gei1bp7pqhjccd.apps.googleusercontent.com'; 
    // Your Client Secret Here
    public Final static String clientSecret= 'HycyI76jFddDHtts51L6kxiR';
    
    public static String googleoAuthUrl='https://accounts.google.com/o/oauth2/auth?'; 
    // Your redirect URI here that you entered while creating the App in Google API console
    public static String redirect_uri = 'https://medical-demo-developer-edition.ap15.force.com/GoogleCalenderoAuth';
    //'https://medical-demo-developer-edition.ap15.force.com/GoogleCalenderoAuth?conId=0032v00003OfRoT'; 
    
    public static String calendar_Scope = 'https://www.googleapis.com/auth/calendar.events+https://www.googleapis.com/auth/userinfo.email'; 
    

    
    /* Constructor */
    public GoogleCalenderApi(){
        
    }
    
//    public PageReference authorization(){
//
//        String request_Body = googleoAuthUrl+'redirect_uri='+redirect_uri+'&response_type=code&client_id='+consumerKey+
//            '&scope='+calendar_Scope+'&prompt=consent&access_type=offline&include_granted_scopes=true';
//
//
//        system.debug('=========>request_Body'+request_Body);
//        PageReference pr = new PageReference(request_Body);
//        return pr;
//    }
    
    public static PageReference doFetchAccessToken(){
        GoogleSetting__c gc = GoogleSetting__c.getInstance('00e2v000004VDEQ');
        if (gc == null) return  null;
        
        String authCode = ApexPages.currentPage().getParameters().get('code');
        String errorMessage = '';
        
        String endPoint = 'https://www.googleapis.com/oauth2/v4/token';
        String authTokenBody = authCode;
        
        String requestTokenBody = 'code='+authCode+'&client_id='+gc.ConsumerKey__c+'&client_secret='+
            gc.ClientSecret__c+'&redirect_uri='+gc.Redirect_uri__c+
            '&grant_type=authorization_code';
        
        Http http = new Http();
        httpRequest httpReq = new httpRequest();
        HttpResponse response = new HttpResponse();
        httpReq.setEndPoint(endPoint);
        httpReq.setBody(requestTokenBody);
        httpReq.setMethod('POST');

        PageReference  pageRefailed= new PageReference('/Failed');
        PageReference pageRef = new PageReference('/ThankYouPage');
        pageRef.setRedirect(true);
        pageRefailed.setRedirect(true);
        try{
            response = http.send(httpReq);
            if(response.getStatuscode()==200){


                Map<String,object> TokenInfo = (Map<String,object>)JSON.deserializeUntyped(response.getBody());
                System.debug('#### TokenInfo '+TokenInfo);
                
                Map<String,object> googlUserInfo = fetchGoogleInfo((String)TokenInfo.get('access_token'));
                system.debug('email======>' + String.valueOf(googlUserInfo.get('email')));
                if(!googlUserInfo.isEmpty() && String.valueOf(googlUserInfo.get('email')) !=null){

                    Contact googleSettingInfo = fetchContactToken(String.valueOf(googlUserInfo.get('email')));
                    
                    if(googleSettingInfo != null ){
                        
                        googleSettingInfo.Access_Token__c = String.valueOf(TokenInfo.get('access_token'));
                        googleSettingInfo.Expire_In__c = Double.valueOf(TokenInfo.get('expires_in'));
                        googleSettingInfo.Refresh_Token__c = String.valueOf(TokenInfo.get('refresh_token'));
                        
                        
                        update googleSettingInfo;

                        return pageRef;
                    }

                }
                

            }else{
                errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
                    +'Status '+response.getStatus()+' and Status Code '+response.getStatuscode();


            }     
        }catch(System.Exception e){

            if(String.valueOf(e.getMessage()).startsWith('Unauthorized endpoint')){
                errorMessage = 'Unauthorize endpoint: An Administer must go to Setup -> Administer -> Security Control ->'
                    +' Remote Site Setting and add '+' '+ endPoint +' Endpoint';


            }else{
                errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
                    +'Status '+response.getStatus()+' and Status Code '+response.getStatuscode();


            }
        }
        return pageRefailed;
    }
    
    public static Map<String,object> fetchGoogleInfo(String accessToken){
                system.debug('accessToken======>' + accessToken);
        String access_Token = accessToken;
        String endPoint = 'https://www.googleapis.com/oauth2/v1/userinfo';
        
        Http http = new Http();
        HttpRequest httpReq = new HttpRequest();
        HttpResponse HttpRes = new HttpResponse();
        
        httpReq.setEndpoint(endpoint);
        httpReq.setMethod('GET');
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Authorization','Bearer '+access_Token);
        try{
            HttpRes = http.send(httpReq);
            if(httpRes.getStatusCode() == 200){
                Map<String,object> googleUserIfo = (Map<String,object>)JSON.deserializeUntyped(HttpRes.getBody());
                System.debug('#### HtteRes '+HttpRes.getBody());
                
                return googleUserIfo;
                
                
            }else{
                String errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
                    +'Status '+HttpRes.getStatus()+' and Status Code '+HttpRes.getStatuscode();
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,errorMessage));
            }
        }catch(System.Exception e){
            System.debug('#### Exception Executed '+e.getStackTraceString() +'  '+e.getMessage());
        }
        
        return null;
    }
    
   /* public static void doRefreshToken(){
        
        String errorMessage ='';
        Contact googleInfoToken = fetchContactToken();
        Http http = new Http();
        HttpRequest httpReq = new HttpRequest();
        HttpResponse httpRes = new HttpResponse();
        httpReq.setEndpoint('https://www.googleapis.com/oauth2/v4/token');
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        
        String refreshToken;
        if(googleInfoToken!=null)
            refreshToken = googleInfoToken.Refresh_Token__c;
        
        System.debug('#### refreshToken '+refreshToken);
        String refreshTokenBody = 'client_id='+consumerKey+'&client_secret='+clientSecret+'&refresh_token='+refreshToken
            +'&grant_type=refresh_token';
        System.debug('#### refreshTokenBody '+refreshTokenBody);
        
        httpReq.setBody(refreshTokenBody);
        
        try{
            httpRes = http.send(httpReq); 
            if(httpRes.getStatusCode() == 200){
                Map<String,object> TokenInfo = (Map<String,object>)JSON.deserializeUntyped(httpRes.getBody());
                Contact googleSettingInfo = fetchContactToken();
                googleSettingInfo.access_token__c = String.valueOf(TokenInfo.get('access_token'));
                googleSettingInfo.Expire_In__c = Double.valueOf(TokenInfo.get('expires_in'));
                //googleSettingInfo.Refresh_Token__c = String.valueOf(TokenInfo.get('refresh_token'));
                System.debug('do Refresh Token '+googleSettingInfo);
                update googleSettingInfo;
            }else{
                errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
                    +'Status '+httpRes.getStatus()+' and Status Code '+httpRes.getStatuscode();
            }
        }catch(System.Exception e){
            
            System.debug('#### Exception Executed '+e.getStackTraceString() + ' '+e.getMessage());
            if(String.valueOf(e.getMessage()).startsWith('Unauthorized endpoint')){
                errorMessage = 'Unauthorize endpoint: An Administer must go to Setup -> Administer -> Security Control ->'
                    +' Remote Site Setting and add '+' '+ 'https://www.googleapis.com/oauth2/v4/token' +' Endpoint';
            }else{
                errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
                    +'Status '+httpRes.getStatus()+' and Status Code '+httpRes.getStatuscode();
            }
        }
    }*/
    
    public static Contact fetchContactToken(String emailStr){
       
        Contact con = [select id, email,access_token__c,Expire_In__c,Refresh_Token__c from contact where email =: emailStr ]; 
        
        return con;
    }
    
    @AuraEnabled
    public static void sendMailMethod(String conID){

        List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();

        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'CalendarAuthorizationEmail'];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        List<String> sendTo = new List<String>();
        
        //mail.setWhatId(conID);
        mail.setSaveAsActivity(false); 
		mail.setTargetObjectId(conID); 
        mail.setReplyTo('noreply@demo-med.com'); 
        mail.setSenderDisplayName('Medical Clinic');
		mail.setTemplateId(emailTemplate.id); 
       
        mails.add(mail);

        Messaging.sendEmail(mails);
    }
}