({
    sendAuthorizationEmail:function(component, event, helper) {
            
            var action = component.get("c.sendMailMethod");
            action.setParams({
                'conID': ''+component.get('v.recordId')+''
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                    if (state === "SUCCESS") {
                        //after code
                        response.getReturnValue();
						console.log(response.getReturnValue());
                        $A.get("e.force:closeQuickAction").fire();
                    } 
            });
            
            $A.enqueueAction(action);
	},
   
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            console.log("You loaded a record in " + 
                        component.get("v.simpleRecord.Name"));
        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    },
    
    handleClose : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire() 
    }


})