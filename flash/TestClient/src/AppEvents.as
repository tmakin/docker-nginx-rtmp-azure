package 
{
	public class AppEvents {
		
        /** Type of the notification dispatched when the user as enabled the camera: the message will be muted / unmuted */
        public static const CAMERA_ENABLED : String = "CameraEnabled";

        /** Type of the notification dispatched when the user as enabled the camera: the message will be muted / unmuted */
        public static const MICROPHONE_ENABLED : String = "MicrophoneEnabled";
		
        /** Type of the notification dispatched periodically while recording */
        public static const RECORDING_TIME : String = "RecordingTime";
        
        /** Type of the notification dispatched when a playback starts */
        public static const STARTED_PLAYING : String = "StartedPlaying";
        
        /** Type of the notification dispatched when a playback pauses */
        public static const PAUSED_PLAYING : String = "PausedPlaying";
        
        /** Type of the notification dispatched when a playback ends */
        public static const END_PLAYING : String = "EndPlaying";
        
        /** Type of the notification dispatched periodically while playing */
        public static const PLAYBACK_TIME : String = "PlaybackTime";
        
        /** Error event */
        public static const ERROR : String = "Error";
	}
}