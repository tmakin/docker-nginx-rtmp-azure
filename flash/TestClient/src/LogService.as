package 
{
	import flash.external.ExternalInterface;
		
	public class LogService 
	{
		public static const DEBUG: String = 'DEBUG';
		public static const INFO: String = 'INFO';
		public static const WARN: String = 'WARN';
		public static const ERROR: String = 'ERROR';
		

		public function log(level: String, msg: String):void {
			
			trace(level.toLocaleUpperCase() + ' :: ' + msg );
			
            if (ExternalInterface.available) {
				
                ExternalInterface.call( 'console.' + level.toLowerCase(), 'Flash : ' +msg );
			}
		}
		
		public function debug(msg: String):void {
			log(DEBUG, msg);
		}
		
		public function info(msg: String): void {
			log(INFO, msg);
		}
		
		public function warn(msg: String): void {
			log(WARN, msg);
		}
		
		public function error(msg: String): void {
			log(ERROR, msg);
		}
	}

}