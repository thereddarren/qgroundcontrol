/*=====================================================================
 
 QGroundControl Open Source Ground Control Station
 
 (c) 2009 - 2014 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 
 This file is part of the QGROUNDCONTROL project
 
 QGROUNDCONTROL is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 QGROUNDCONTROL is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with QGROUNDCONTROL. If not, see <http://www.gnu.org/licenses/>.
 
 ======================================================================*/

#include "MissionControllerTest.h"
#include "LinkManager.h"
#include "MultiVehicleManager.h"

MissionControllerTest::MissionControllerTest(void)
    : _multiSpyMissionController(NULL)
    , _multiSpyMissionItem(NULL)
    , _missionController(NULL)
{
    
}

void MissionControllerTest::cleanup(void)
{
    delete _missionController;
    _missionController = NULL;

    delete _multiSpyMissionController;
    _multiSpyMissionController = NULL;

    delete _multiSpyMissionItem;
    _multiSpyMissionItem = NULL;

    MissionControllerManagerTest::cleanup();
}

void MissionControllerTest::_initForFirmwareType(MAV_AUTOPILOT firmwareType)
{
    bool startController = false;

    MissionControllerManagerTest::_initForFirmwareType(firmwareType);

    void coordinateChanged(const QGeoCoordinate& coordinate);
    void headingDegreesChanged(double heading);
    void dirtyChanged(bool dirty);
    void homePositionValidChanged(bool homePostionValid);

    // MissionItem signals
    _rgMissionItemSignals[coordinateChangedSignalIndex] = SIGNAL(coordinateChanged(const QGeoCoordinate&));

    // MissionController signals
    _rgMissionControllerSignals[missionItemsChangedSignalIndex] =   SIGNAL(missionItemsChanged());
    _rgMissionControllerSignals[waypointLinesChangedSignalIndex] =  SIGNAL(waypointLinesChanged());

    if (!_missionController) {
        startController = true;
        _missionController = new MissionController();
        Q_CHECK_PTR(_missionController);
    }

    _multiSpyMissionController = new MultiSignalSpy();
    Q_CHECK_PTR(_multiSpyMissionController);
    QCOMPARE(_multiSpyMissionController->init(_missionController, _rgMissionControllerSignals, _cMissionControllerSignals), true);

    if (startController) {
        _missionController->start(false /* editMode */);
    }

    // All signals should some through on start
    QCOMPARE(_multiSpyMissionController->checkOnlySignalsByMask(missionItemsChangedSignalMask | waypointLinesChangedSignalMask), true);
    _multiSpyMissionController->clearAllSignals();

    QmlObjectListModel* missionItems = _missionController->missionItems();
    QVERIFY(missionItems);

    // Empty vehicle only has home position
    QCOMPARE(missionItems->count(), 1);

    // Home position should be in first slot, but not yet valid
    MissionItem* homeItem = qobject_cast<MissionItem*>(missionItems->get(0));
    QVERIFY(homeItem);
    QCOMPARE(homeItem->homePosition(), true);

    // Home should have no children
    QCOMPARE(homeItem->childItems()->count(), 0);

    // No waypoint lines
    QmlObjectListModel* waypointLines = _missionController->waypointLines();
    QVERIFY(waypointLines);
    QCOMPARE(waypointLines->count(), 0);

    // AutoSync should be off by default
    QCOMPARE(_missionController->autoSync(), false);
}

void MissionControllerTest::_testEmptyVehicleWorker(MAV_AUTOPILOT firmwareType)
{
    _initForFirmwareType(firmwareType);

    // FYI: A significant amount of empty vehicle testing is in _initForFirmwareType since that
    // sets up an empty vehicle

    QmlObjectListModel* missionItems = _missionController->missionItems();
    QVERIFY(missionItems);
    MissionItem* homeItem = qobject_cast<MissionItem*>(missionItems->get(0));
    QVERIFY(homeItem);

    _setupMissionItemSignals(homeItem);
}

void MissionControllerTest::_testEmptyVehiclePX4(void)
{
    _testEmptyVehicleWorker(MAV_AUTOPILOT_PX4);
}

void MissionControllerTest::_testEmptyVehicleAPM(void)
{
    _testEmptyVehicleWorker(MAV_AUTOPILOT_ARDUPILOTMEGA);
}

void MissionControllerTest::_testAddWaypointWorker(MAV_AUTOPILOT firmwareType)
{
    _initForFirmwareType(firmwareType);

    QGeoCoordinate coordinate(37.803784, -122.462276);

    _missionController->insertSimpleMissionItem(coordinate, _missionController->missionItems()->count());

    QCOMPARE(_multiSpyMissionController->checkOnlySignalsByMask(waypointLinesChangedSignalMask), true);

    QmlObjectListModel* missionItems = _missionController->missionItems();
    QVERIFY(missionItems);

    QCOMPARE(missionItems->count(), 2);

    MissionItem* homeItem = qobject_cast<MissionItem*>(missionItems->get(0));
    MissionItem* item = qobject_cast<MissionItem*>(missionItems->get(1));
    QVERIFY(homeItem);
    QVERIFY(item);

    QCOMPARE(item->command(), MavlinkQmlSingleton::MAV_CMD_NAV_TAKEOFF);
    QCOMPARE(homeItem->childItems()->count(), firmwareType == MAV_AUTOPILOT_ARDUPILOTMEGA ? 1 : 0);
    QCOMPARE(item->childItems()->count(), 0);

#if 0
    // This needs re-work
    int expectedLineCount = firmwareType == MAV_AUTOPILOT_ARDUPILOTMEGA ? 0 : 1;

    QmlObjectListModel* waypointLines = _missionController->waypointLines();
    QVERIFY(waypointLines);
    QCOMPARE(waypointLines->count(), expectedLineCount);
#endif
}

void MissionControllerTest::_testAddWayppointAPM(void)
{
    _testAddWaypointWorker(MAV_AUTOPILOT_ARDUPILOTMEGA);
}


void MissionControllerTest::_testAddWayppointPX4(void)
{
    _testAddWaypointWorker(MAV_AUTOPILOT_PX4);
}

void MissionControllerTest::_testOfflineToOnlineWorker(MAV_AUTOPILOT firmwareType)
{
    // Start offline and add item
    _missionController = new MissionController();
    Q_CHECK_PTR(_missionController);
    _missionController->start(true /* editMode */);
    _missionController->insertSimpleMissionItem(QGeoCoordinate(37.803784, -122.462276), _missionController->missionItems()->count());

    // Go online to empty vehicle
    MissionControllerManagerTest::_initForFirmwareType(firmwareType);

    // Make sure our offline mission items are still there
    QCOMPARE(_missionController->missionItems()->count(), 2);
}

void MissionControllerTest::_testOfflineToOnlineAPM(void)
{
    _testOfflineToOnlineWorker(MAV_AUTOPILOT_ARDUPILOTMEGA);
}

void MissionControllerTest::_testOfflineToOnlinePX4(void)
{
    _testOfflineToOnlineWorker(MAV_AUTOPILOT_PX4);
}

void MissionControllerTest::_setupMissionItemSignals(MissionItem* item)
{
    delete _multiSpyMissionItem;

    _multiSpyMissionItem = new MultiSignalSpy();
    Q_CHECK_PTR(_multiSpyMissionItem);
    QCOMPARE(_multiSpyMissionItem->init(item, _rgMissionItemSignals, _cMissionItemSignals), true);
}
