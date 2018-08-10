package 
{
	public class AppStates {
		/** recorder is initializing. This includes ensuring camera access */
		public static const INIT : String = "Init";
		
		/** Type of the notification dispatched when the object is initialized */
		public static const READY : String = "Ready";
		
		/** Error occurred during startup **/
		public static const ERROR : String = "Error";
		 
		/** Type of the notification dispatched when a recording is in progress */
		public static const RECORDING : String = "Recording";
		
		/** Type of the notification dispatched when a recording stops or playback ends */
		public static const DONE : String = "Done";
		
		/** Type of the notification dispatched when a playback is active */
        public static const PLAYBACK : String = "Playback";
	}
}