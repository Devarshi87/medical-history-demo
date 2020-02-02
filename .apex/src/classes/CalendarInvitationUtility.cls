public class CalendarInvitationUtility {

	public static void sendinvite(String physicianEmail, String patientEmail , Event eventObj ) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new List<String>{physicianEmail , patientEmail});
		mail.setSubject(eventObj.Subject);
		mail.setPlainTextBody('');
		Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
		attach.filename = 'invite.ics';
		attach.ContentType = 'text/calendar';
		attach.inline = true;
		attach.body = invite( physicianEmail, patientEmail, eventObj );
		mail.setFileAttachments(new Messaging.EmailFileAttachment[] {attach});
		Messaging.SendEmailResult[] er = Messaging.sendEmail(new Messaging.Email[] { mail });
	}

	private static Blob invite(String physicianEmail, String patientEmail ,Event eventObj) {
		DateTime endTime=eventObj.EndDateTime;
		Datetime starttime = eventObj.StartDateTime;
		DateTime dt=DateTime.now().adddays(1);
		String nowtime=String.valueof(dt.year()+'0'+dt.month()+''+dt.day()+'T000000Z');
		String startdatetime=String.valueof(starttime.year()+'0'+starttime.month()+''+starttime.day()+'T'+starttime.hour()+starttime.minute()+'00Z');
		String enddatetime=String.valueof(endTime.year()+'0'+endTime.month()+''+endTime.day()+'T'+endTime.hour()+endTime.minute()+'00Z');
		String txtInvite = '';
		txtInvite += 'BEGIN:VCALENDAR\n';
		txtInvite += 'PRODID::-//Medical Clinic/demo//medCn v1.0//EN\n';
		txtInvite += 'VERSION:2.0\nCALSCALE:GREGORIAN\n';
		txtInvite += 'METHOD:REQUEST\n';
		txtInvite += 'X-MS-OLK-FORCEINSPECTOROPEN:TRUE\n';
		txtInvite += 'BEGIN:VEVENT\n';

		txtInvite += 'CREATED:'+nowtime+'\n';
		txtInvite += 'DTEND:'+enddatetime+'\n';
		txtInvite += 'DTSTAMP:'+nowtime+'\n';
		txtInvite += 'DTSTART:'+startdatetime+'\n';
		txtInvite += 'ORGANIZER;CN='+ physicianEmail +':mailto:'+physicianEmail+'\n';
		txtInvite += 'ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE;CN='+patientEmail+';X-NUM-GUESTS=0:mailto:'+patientEmail+'\n';
		txtInvite += 'LAST-MODIFIED:'+nowtime+'\n';
		txtInvite += 'LOCATION:India\n';
		txtInvite += 'PRIORITY:5\n';
		txtInvite += 'SEQUENCE:0\n';
		txtInvite += 'SUMMARY:'+eventObj.Subject+'\n';
		txtInvite += 'LANGUAGE=en-us\n';
		txtInvite += 'TRANSP:OPAQUE\n';
		txtInvite += 'X-ALT-DESC;FMTTYPE=text/html:<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN"><HTML><HEAD><META NAME="Generator" CONTENT="MS Exchange Server version 08.00.0681.000"><TITLE></TITLE></HEAD><BODY><!-- Converted from text/plain format --></BODY></HTML>\n';
		txtInvite += 'X-MICROSOFT-CDO-BUSYSTATUS:BUSY\n';
		txtInvite += 'X-MICROSOFT-CDO-IMPORTANCE:1\n';
		txtInvite += 'END:VEVENT\n';
		txtInvite += 'END:VCALENDAR';
		return Blob.valueOf(txtInvite);
	}

	public static void doCreateNewCalendarEvent(Contact googleContInfo, String pateintEmail, Event eventObj){

		String accessToken = googleContInfo.Access_Token__c;
//		DateTime endTime= eventObj.EndDateTime;
//		Datetime starttime = eventObj.StartDateTime.format('YYYY-MM-DDTHH:mm:ssZ');
		String startdatetime= eventObj.StartDateTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ');
		String enddatetime=eventObj.EndDateTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ');

		String createEventEndPoint = 'https://www.googleapis.com/calendar/v3/calendars/primary/events?sendNotifications=true';

		String createEventBody =  '{' +
				'"attendees": ['+
				'{'+
				'"email": "happydevshop@gmail.com"'+
				'},'+
				'{'+
				'"email": "'+googleContInfo.Email+'"'+
				'},'+
				'{'+
				'"email": "'+pateintEmail+'"'+
				'}'+
				'],'+
				'"attachments": ['+
				'{'+
				'"fileUrl": ""'+
				'}'+
				'],'+
				'"end": {'+
				'"dateTime": "'+enddatetime+'"'+
				'},'+
				'"reminders": {'+
				'"useDefault": true'+
				'},'+
				'"start": {'+
				'"dateTime": "'+startdatetime+'"'+
				'},'+
				'"summary": "'+eventObj.Subject+'",'+
				'"location": "Medical Clinic Demo Center"'+
				'}';
		System.debug('#### createEventBody  '+createEventBody );
		Http http = new Http();
		HttpRequest httpReq = new HttpRequest();
		HttpResponse HttpRes = new HttpResponse();

		httpReq.setEndpoint(createEventEndPoint);
		httpReq.setMethod('POST');
		httpReq.setBody(createEventBody );
		httpReq.setHeader('Content-Type', 'application/json');
		httpReq.setHeader('Authorization','Bearer '+accessToken);
		try{
			HttpRes = http.send(httpReq);
			if(HttpRes.getStatusCode() == 200){
				ApexPages.addmessage(new ApexPages.message(
						ApexPages.severity.CONFIRM,'Calendar Event Successfully  '+'\n'+' '+
								HttpRes.getBody()));
				Map<String,object> event_res = (Map<String,object>)JSON.deserializeUntyped(HttpRes.getBody());

				eventObj.Google_Cal_Event_Id__c = (String)event_res.get('id');
				update eventObj;
			}
			else{
				String errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
						+'Status '+HttpRes.getStatus()+' and Status Code '+HttpRes.getStatuscode();
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,errorMessage));
			}
		}catch(System.Exception e){
			System.debug('#### Exception Executed : '+e.getMessage() + '  '+e.getStackTraceString() + ' '+e.getLineNumber());
		}
	}

	public static Contact doRefreshToken(Contact physician){

		GoogleSetting__c gc = GoogleSetting__c.getInstance('00e2v000004VDEQ');
		if (gc != null) {

		String errorMessage ='';
		Contact googleInfoToken = physician;
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
		String refreshTokenBody = 'client_id='+gc.ConsumerKey__c+'&client_secret='+gc.ClientSecret__c+'&refresh_token='+refreshToken
				+'&grant_type=refresh_token';
		System.debug('#### refreshTokenBody '+refreshTokenBody);

		httpReq.setBody(refreshTokenBody);

		try{
			httpRes = http.send(httpReq);
			if(httpRes.getStatusCode() == 200){
				Map<String,object> TokenInfo = (Map<String,object>)JSON.deserializeUntyped(httpRes.getBody());

				googleInfoToken.access_token__c = String.valueOf(TokenInfo.get('access_token'));
				googleInfoToken.Expire_In__c = Double.valueOf(TokenInfo.get('expires_in'));
				 googleInfoToken.Token_update_time__c = System.now();
				//googleSettingInfo.Refresh_Token__c = String.valueOf(TokenInfo.get('refresh_token'));
				System.debug('do Refresh Token '+googleInfoToken);
				//update googleInfoToken;

				return googleInfoToken;
			}else{
				errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
						+'Status '+httpRes.getStatus()+' and Status Code '+httpRes.getStatuscode();
			}
			return googleInfoToken;
		}catch(System.Exception e){

			System.debug('#### Exception Executed '+e.getStackTraceString() + ' '+e.getMessage());
			if(String.valueOf(e.getMessage()).startsWith('Unauthorized endpoint')){
				errorMessage = 'Unauthorize endpoint: An Administer must go to Setup -> Administer -> Security Control ->'
						+' Remote Site Setting and add '+' '+ 'https://www.googleapis.com/oauth2/v4/token' +' Endpoint';
			}else{
				errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
						+'Status '+httpRes.getStatus()+' and Status Code '+httpRes.getStatuscode();
			}

			return physician;
		}


		}
		return physician;
	}

	public static void deleteCalendarEvent(Contact googleContInfo, String gcalid){

		String accessToken = googleContInfo.Access_Token__c;
		Http http = new Http();
		HttpRequest httpReq = new HttpRequest();
		HttpResponse HttpRes = new HttpResponse();
		String deleteEventEndpoint = 'https://www.googleapis.com/calendar/v3/calendars/primary/events/'+gcalid;
		httpReq.setEndpoint(deleteEventEndpoint);
		httpReq.setMethod('DELETE');

		httpReq.setHeader('Content-Type', 'application/json');
		httpReq.setHeader('Authorization','Bearer '+accessToken);
		try{
			HttpRes = http.send(httpReq);
			if(HttpRes.getStatusCode() == 200){
				ApexPages.addmessage(new ApexPages.message(
						ApexPages.severity.CONFIRM,'Calendar Event Successfully deleted  '+'\n'+' '+
								HttpRes.getBody()));
				Map<String,object> event_res = (Map<String,object>)JSON.deserializeUntyped(HttpRes.getBody());

//				eventObj.Google_Cal_Event_Id__c = (String)event_res.get('id');
//				update eventObj;
			}else{
				String errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
						+'Status '+HttpRes.getStatus()+' and Status Code '+HttpRes.getStatuscode();
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,errorMessage));
			}
		}catch(System.Exception e){
			System.debug('#### Exception Executed : '+e.getMessage() + '  '+e.getStackTraceString() + ' '+e.getLineNumber());
		}
	}
}