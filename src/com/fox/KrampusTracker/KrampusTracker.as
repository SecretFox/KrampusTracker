import com.GameInterface.Game.Dynel;
import com.GameInterface.Nametags;
import com.GameInterface.Waypoint;
import com.GameInterface.WaypointInterface;
import com.Utils.ID32;
import com.Utils.LDBFormat;
import com.fox.KrampusTracker.Utils;
import flash.geom.Point;
import mx.utils.Delegate;

class fox.KrampusTracker.KrampusTracker {
	private var m_swfRoot: MovieClip;
	private var m_dynels:Array;
	private var m_screenWidth:Number;
	private var KrampiString:String = LDBFormat.LDBGetText(51000, 33735)

	public static function main(swfRoot:MovieClip):Void {
		var Mod = new KrampusTracker(swfRoot);

		swfRoot.onLoad = function() { Mod.OnLoad(); };
		swfRoot.OnUnload = function() { Mod.OnUnload(); };
	}

	public function KrampusTracker(swfRoot: MovieClip) {
		m_swfRoot = swfRoot;
	}

	public function OnUnload() {
		m_swfRoot.onEnterFrame = undefined;

		Nametags.SignalNametagAdded.Disconnect(Add, this);
		Nametags.SignalNametagRemoved.Disconnect(Remove, this);
		Nametags.SignalNametagUpdated.Disconnect(Add, this);

		WaypointInterface.SignalPlayfieldChanged.Disconnect(PlayFieldChanged, this);

		for (var i in m_dynels) {
			Remove(m_dynels[i]);
		}
	}

	public function OnLoad() {
		m_dynels = [];
		m_swfRoot.onEnterFrame = Delegate.create(this, OnFrame);

		m_screenWidth = Stage["visibleRect"].width;

		Nametags.SignalNametagAdded.Connect(Add, this);
		Nametags.SignalNametagRemoved.Connect(Remove, this);
		Nametags.SignalNametagUpdated.Connect(Add, this);

		Nametags.RefreshNametags();

		WaypointInterface.SignalPlayfieldChanged.Connect(PlayFieldChanged, this);
	}

	private function OnFrame() {
		for (var i in m_dynels) {
			var dynel:Dynel = m_dynels[i];
			if (dynel.IsDead()){
				Remove(dynel);
				return;
			}
			
			var waypoint/*:ScreenWaypoint*/ = _root.waypoints.m_RenderedWaypoints[dynel.GetID()];
			waypoint.m_Waypoint.m_DistanceToCam = dynel.GetCameraDistance();
			var screenPosition:Point = dynel.GetScreenPosition();
			waypoint.m_Waypoint.m_ScreenPositionX = screenPosition.x;
			waypoint.m_Waypoint.m_ScreenPositionY = screenPosition.y;
			waypoint.Update(m_screenWidth);
			waypoint = undefined;
		}
	}

	private function Add(id:ID32) {
        var dynel:Dynel = Dynel.GetDynel(id);
		if (Utils.Contains(m_dynels, dynel)) return; //Already tracking

		if (dynel.GetName() == KrampiString) {
			var waypoint:Waypoint = new Waypoint();
			waypoint.m_WaypointType = _global.Enums.WaypointType.e_RMWPScannerBlip;
			waypoint.m_WaypointState = _global.Enums.QuestWaypointState.e_WPStateActive;
			waypoint.m_IsScreenWaypoint = true;
			waypoint.m_IsStackingWaypoint = true;
			waypoint.m_Radius = 0;
			waypoint.m_Color = 0xFF0000;
			waypoint.m_CollisionOffsetX = 0;
			waypoint.m_CollisionOffsetY = 0;
			waypoint.m_MinViewDistance = 0;
			waypoint.m_MaxViewDistance = 500;
			waypoint.m_Id = dynel.GetID();
			waypoint.m_Label = dynel.GetName();
			waypoint.m_WorldPosition = dynel.GetPosition();
			var screenPosition:Point = dynel.GetScreenPosition();
			waypoint.m_ScreenPositionX = screenPosition.x;
			waypoint.m_ScreenPositionY = screenPosition.y;
			waypoint.m_DistanceToCam = dynel.GetCameraDistance();

			_root.waypoints.m_CurrentPFInterface.m_Waypoints[dynel.GetID().toString()] = waypoint;
			_root.waypoints.m_CurrentPFInterface.SignalWaypointAdded.Emit(waypoint.m_Id);
			m_dynels.push(dynel);

		}
	}

	private function Remove(dynel:Dynel) {
		Utils.Remove(m_dynels, dynel);
		delete _root.waypoints.m_CurrentPFInterface.m_Waypoints[dynel.GetID().toString];
		_root.waypoints.m_CurrentPFInterface.SignalWaypointRemoved.Emit(dynel.GetID());
	}
	
	private function PlayFieldChanged() {
		m_dynels = [];
	}

}