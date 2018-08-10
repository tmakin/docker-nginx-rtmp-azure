package 
{
	import flash.external.ExternalInterface;
			
	public class NotificationService 
	{
		private var _jsListener: String;
		private var _log: LogService;
		
		public static const STATE: String = "State";
		public static const EVENT: String = "Event";

		public function NotificationService(log: LogService, jsListener: String) 
		{
			_jsListener = jsListener;
			_log = log;
			
			_log.debug('jsListener=' + jsListener);
		}
		
		public function notifyState( name:String, message:String = null):void
        {
			notify(STATE, name, message);
		}

		public function notifyEvent(name:String, data:Object = null):void
        {
			notify(EVENT, name, data);
        }
		
		public function notifyTime(name:String, time:int):void
        {
			notify(EVENT, name, time);
        }
		
		private function notify(type: String, name: String, data:Object = null): void {
			
			_log.debug(type +" : "+ name +" : "+ data);
						
            if ( !_jsListener || !ExternalInterface.available )
			{
                return;
			}

            ExternalInterface.call(_jsListener, {type:type, name:name, data:data} );
		}
		

	}
}