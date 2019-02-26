registerController('PMKIDAttack_IsConnected', ['$api', '$scope', '$rootScope', '$interval', function ($api, $scope, $rootScope, $interval) {
    $rootScope.isConnected = false;
    $rootScope.noDependencies = false;
    $rootScope.running = false;
    $rootScope.accessPoints = [];
    $rootScope.unassociatedClients = [];
    $rootScope.outOfRangeClients = [];
    $rootScope.captureRunning = false;
    $rootScope.log         = "LOG";

    var isConnected = function () {
        $api.request({
            module: "PMKIDAttack",
            action: "isConnected"
        }, function (response) {
            if (!response.success) {
                $rootScope.isConnected = true;
            } else {
                $rootScope.isConnected = false;
            }
        });
    };

    $api.request({
        module: "PMKIDAttack",
        action: "getDependenciesStatus"
    }, function (response) {
        if (response.install == 'Install') {
            $rootScope.noDependencies = true;
            isConnected();
        }

        console.log(response.install);
    });

    var interval = $interval(function () {
        if (!$rootScope.isConnected) {
            $interval.cancel(interval);
        } else {
            isConnected();
        }
    }, 5000);
}]);

registerController('PMKIDAttack_Log', ['$api', '$scope', '$rootScope', '$interval', function ($api, $scope, $rootScope, $interval) {
    $scope.wipe         = "Clear";
    $scope.clear         = "Clear";

    $scope.wipeLog = (function () {
        $api.request({
            module: "PMKIDAttack",
            action: "wipeLog"
        }, function (response) {
        })
    });
 
    var interval = $interval(function () {
        $api.request({
            module: "PMKIDAttack",
            action: "getLog"
        }, function (response) {
    	    $scope.pmkidlog         = response.pmkidlog;
        })
    }, 2000);

}]);

registerController('PMKIDAttack_Dependencies', ['$api', '$scope', '$rootScope', '$interval', function ($api, $scope, $rootScope, $interval) {
    $scope.install = "Loading...";
    $scope.installLabel = "default";
    $scope.processing = false;
    $rootScope.handshakeInfo = false;

    $rootScope.status = {
        installed: false,
        generated: false,
        refreshOutput: false,
        refreshKnownHosts: false
    };

    $scope.refreshStatus = (function () {
        $api.request({
            module: "PMKIDAttack",
            action: "getDependenciesStatus"
        }, function (response) {
            $scope.status.installed = response.installed;
            $scope.processing = response.processing;
            $scope.install = response.install;
            $scope.installLabel = response.installLabel;

            if ($scope.processing) {
                $scope.statusDependencies();
            }
        })
    });

    $scope.statusDependencies = (function () {
        var statusDependenciesInterval = $interval(function () {
            $api.request({
                module: 'PMKIDAttack',
                action: 'statusDependencies'
            }, function (response) {
                if (response.success === true) {
                    $scope.processing = false;
                    $rootScope.noDependencies = false;
                    $scope.refreshStatus();
                    $interval.cancel(statusDependenciesInterval);
                }
            });
        }, 2000);
    });


  $scope.forceManagerDependencies = (function () {
        if ($scope.status.installed) {
            $scope.install = "Installing...";
        } else {
            $scope.install = "Removing...";
        }

        $api.request({
            module: 'PMKIDAttack',
            action: 'forceManagerDependencies'
        }, function (response) {
            if (response.success === true) {
                $scope.installLabel = "warning";
                $scope.processing = true;
                $scope.statusDependencies();
            }
        });
    });

    $scope.managerDependencies = (function () {
        if ($scope.status.installed) {
            $scope.install = "Installing...";
        } else {
            $scope.install = "Removing...";
        }

        $api.request({
            module: 'PMKIDAttack',
            action: 'managerDependencies'
        }, function (response) {
            if (response.success === true) {
                $scope.installLabel = "warning";
                $scope.processing = true;
                $scope.statusDependencies();
            }
        });
    });

    $scope.refreshStatus();
}]);

registerController('PMKIDAttack_ScanSettings', ['$api', '$scope', '$rootScope', '$interval', '$timeout', '$cookies', function ($api, $scope, $rootScope, $interval, $timeout, $cookies) {
    $rootScope.pmkids = [];
    $scope.scans = [];
    $scope.selectedScan = "";
    $scope.loadedScan = null;
    $scope.scanType = '0';
    $scope.paused = false;
    $scope.percent = 0;
    $scope.error = false;
    $scope.pineAPDRunning = true;
    $scope.pineAPDStarting = false;
    $scope.percentageInterval = 300;
    $scope.wsAuthToken = "";
    $scope.scanSettings = {
        scanDuration: $cookies.get('scanDuration') !== undefined ? $cookies.get('scanDuration') : '0',
        live: $cookies.get('liveScan') !== undefined ? $cookies.get('liveScan') === 'true' : true
    };

    function checkScanStatus() {
        if ($scope.scanSettings.scanDuration < 1) {
            return;
        }
        if (!$scope.updatePercentageInterval) {
            $scope.updatePercentageInterval = $interval(function () {
                var percentage = $scope.percentageInterval / ($scope.scanSettings.scanDuration * 10);
                if (($scope.percent + percentage) >= 100 && $rootScope.running && !$scope.loading) {
                    $scope.percent = 100;
                    $scope.checkScan();
                } else if ($scope.percent + percentage < 100 && $rootScope.running) {
                    $scope.percent += percentage;
                }
            }, $scope.percentageInterval);
        }
    }

    function parseScanResults(results) {
        annotateMacs();
        var data = results['results'];
        $rootScope.accessPoints = data['ap_list'];
        $rootScope.unassociatedClients = data['unassociated_clients'];
        $rootScope.outOfRangeClients = data['out_of_range_clients'];
    }

    $rootScope.viewLog = function (pathPMKID = '') {
        $api.request({
            action: 'getOutput',
            module: 'PMKIDAttack',
            pathPMKID: pathPMKID
        }, function (response) {
            if (response.output) {
                $rootScope.output = response.output;
            }
        });
    };

    $rootScope.getPMKIDFiles = function () {
        $api.request({
            action: 'getPMKIDFiles',
            module: 'PMKIDAttack',
        }, function (response) {
            $rootScope.pmkids = response.pmkids;
        });
    };

    $rootScope.getPMKIDFiles();

    $rootScope.stopAttack = function () {
        $api.request({
            action: 'stopAttack',
            module: 'PMKIDAttack',
            bssid: $rootScope.mac
        }, function (response) {
            $interval.cancel($rootScope.intervalCheckHash);
            delete $rootScope.intervalCheckHash;
            $rootScope.captureRunning = false;
            $rootScope.getPMKIDFiles();
        });
    };

    $scope.downloadPMKID = function (file) {
        $api.request({
            action: 'downloadPMKID',
            module: 'PMKIDAttack',
            file: file
        }, function (response) {
            window.location = '/api/?download=' + response.download;
        });
    };

    $scope.deletePMKID = function (file) {
        $api.request({
            action: 'deletePMKID',
            module: 'PMKIDAttack',
            file: file
        }, function (response) {
            $rootScope.getPMKIDFiles();
        });
    };

    $scope.updateScanSettings = function () {
        $cookies.put('scanDuration', $scope.scanSettings.scanDuration);
        if ($scope.scanSettings.scanDuration === "0") {
            $scope.scanSettings.live = true;
        }
        $cookies.put('liveScan', $scope.scanSettings.live);
        ($cookies.getAll());
    };

    $scope.startScan = function () {
        $scope.percent = 0;
        if ($rootScope.running) {
            return;
        }
        if ($scope.scanSettings.scanDuration === "0") {
            $scope.scanSettings.live = true;
        }
        if ($scope.scanSettings.live === true) {
            $scope.startLiveScan();
        } else {
            $scope.startNormalScan();
        }
        $rootScope.accessPoints = [];
        $rootScope.unassociatedClients = [];
        $rootScope.outOfRangeClients = [];
        checkScanStatus();
    };

    $scope.startLiveScan = function () {
        $scope.loading = true;

        $api.request({
            module: 'Recon',
            action: 'startLiveScan',
            scanType: $scope.scanType,
            scanDuration: $scope.scanSettings.scanDuration
        }, function (response) {
            if (response.success) {
                $scope.loading = false;
                $rootScope.running = true;
                $scope.scanID = response.scanID;
                if ($scope.wsStarted !== true) {
                    $scope.startWS();
                }
            } else {
                if (response.error === "The PineAP Daemon must be running.") {
                    $scope.pineAPDRunning = false;
                }
                $scope.error = response.error;
            }
        });
    };

    $scope.startWS = (function () {
        $scope.wsStarted = true;
        $api.request({
            module: 'Recon',
            action: 'getWSAuthToken'
        }, function (response) {
            if (response.success === true) {
                $scope.wsAuthToken = response.wsAuthToken;
                $scope.doWS();
            } else {
                $scope.wsTimeout = $timeout($scope.startWS, 1500);
            }
        });
    });

    $scope.doWS = (function () {
        if ($scope.ws !== undefined && $scope.ws.readyState !== WebSocket.CLOSED) {
            return;
        }
        $scope.ws = new WebSocket("ws://" + window.location.hostname + ":1337/?authtoken=" + $scope.wsAuthToken);
        $scope.ws.onerror = (function () {
            $scope.wsTimeout = $timeout($scope.startWS, 1000);
        });
        $scope.ws.onopen = (function () {
            $scope.ws.onerror = (function () {
            });
            $rootScope.running = true;

        });
        $scope.ws.onclose = (function () {
            $scope.listening = false;
            $scope.closeWS();
        });

        $scope.ws.onmessage = (function (message) {
            $scope.listening = true;
            if ($scope.paused) {
                return;
            }
            var data = JSON.parse(message.data);
            if (data.scan_complete === true) {
                $scope.checkScan();
                return;
            }
            $rootScope.accessPoints = data.ap_list;
            $rootScope.unassociatedClients = data.unassociated_clients;
            $rootScope.outOfRangeClients = data.out_of_range_clients;
            annotateMacs();
        });
    });

    $scope.startNormalScan = function () {
        if ($rootScope.running) {
            return;
        }

        $scope.loading = true;

        $api.request({
            module: 'Recon',
            action: 'startNormalScan',
            scanType: $scope.scanType,
            scanDuration: $scope.scanSettings.scanDuration
        }, function (response) {
            if (response.success) {
                $scope.loading = false;
                $rootScope.running = true;
                $scope.scanID = response.scanID;
            } else {
                if (response.error === "The PineAP Daemon must be running.") {
                    $scope.pineAPDRunning = false;
                }
                $scope.error = response.error;
            }
        });
    };

    $scope.pauseLiveScan = function () {
        $scope.paused = true;
    };

    $scope.resumeLiveScan = function () {
        $scope.paused = false;
    };

    $scope.stopScan = function () {
        $scope.percent = 0;
        $scope.paused = false;
        $rootScope.running = false;

        $api.request({
            module: 'Recon',
            action: 'stopScan'
        }, function (response) {
            if (response.success === true) {
                $rootScope.running = false;
                $scope.closeWS();
            }
        });
    };

    $scope.checkScan = function () {
        $api.request({
            module: 'Recon',
            action: 'checkScanStatus',
            scanID: $scope.scanID
        }, function (response) {
            $scope.percent = response.scanPercent;
            if (response.error) {
                $scope.error = response.error;
            } else if (response.completed === true) {
                if (!$rootScope.running && !$scope.loading) {
                    $scope.percent = 100;
                }
                if ($rootScope.running) {
                    $scope.stopScan();
                    $scope.scans = $scope.scans || [];
                    $scope.selectedScan = $scope.scans[$scope.scans.length - 1];
                    $scope.displayScan();
                }
            } else if (response.completed === false) {
                if (response.scanID !== null && response.scanID !== undefined) {
                    $scope.scanID = response.scanID;
                }
            }
        });
    };

    $scope.displayScan = function () {
        if ($scope.selectedScan === undefined) {
            return;
        }

        $scope.loadingScan = true;
        $api.request({
            module: 'Recon',
            action: 'getScans'
        }, function (response) {
            if (response.error === undefined) {
                $scope.scans = response.scans;
                $api.request({
                    module: 'Recon',
                    action: 'loadResults',
                    scanID: $scope.selectedScan['scan_id']
                }, function (response) {
                    parseScanResults(response);
                    $scope.loadingScan = false;
                    $scope.loadedScan = $scope.selectedScan;
                    $scope.scanID = $scope.selectedScan['scan_id'];
                });
            } else {
                $scope.error = response.error;
            }
        });
    };

    $scope.cancelIntervals = function () {
        if ($scope.checkScanInterval) {
            $interval.cancel($scope.checkScanInterval);
        }
        if ($scope.updatePercentageInterval) {
            $interval.cancel($scope.updatePercentageInterval);
        }

        if ($scope.wsTimeout) {
            $timeout.cancel($scope.wsTimeout);
        }
        $scope.checkScanInterval = null;
        $scope.updatePercentageInterval = null;
        $scope.wsTimeout = null;
    };

    $scope.closeWS = (function () {
        if ($scope.ws !== undefined) {
            $scope.ws.close();
            $scope.wsStarted = false;
        }
    });

    $scope.displayCurrentScan = function () {
        $api.request({
            module: 'Recon',
            action: 'checkScanStatus'
        }, function (response) {
            if (!response.completed && response.scanID !== null) {
                $scope.scanID = response.scanID;
                $scope.loading = true;
                if (response.continuous) {
                    $scope.scanSettings.scanDuration = "0";
                    $scope.scanSettings.live = true;
                    $scope.percent = response.scanPercent;
                }
                $api.request({
                    module: 'Recon',
                    action: 'startReconPP'
                }, function () {
                    if ($scope.wsStarted !== true) {
                        $scope.startWS();
                    }
                    $rootScope.running = true;
                    checkScanStatus();
                    $scope.loading = false;
                });
            }
        });
    };

    $scope.startPineAP = function () {
        $scope.pineAPDStarting = true;
        $api.request({
            module: 'Recon',
            action: 'startPineAPDaemon'
        }, function (response) {
            $scope.pineAPDStarting = false;
            if (response.error === undefined) {
                $scope.pineAPDRunning = true;
                $scope.error = null;
            } else {
                $scope.error = response.error;
            }
        });
    };

    $scope.checkScan();

    $scope.$on('$destroy', function () {
        $scope.cancelIntervals();
        $scope.closeWS();
    });

    $api.onDeviceIdentified(function (device) {
        $scope.updateScanSettings();
        $scope.device = device;
        $scope.displayCurrentScan();
    }, $scope);
}]);


registerController('PMKIDAttack_ScanResults', ['$api', '$scope', '$interval', '$rootScope', function ($api, $scope, $interval, $rootScope) {
    $scope.reverseSort = false;
    $scope.orderByName = 'ssid';
    $rootScope.mac = '';

    $api.request({
        action: "getStatusAttack",
        module: "PMKIDAttack"
    }, function (response) {
        if (response.success) {
            $rootScope.captureRunning = true;
            if (!$rootScope.intervalCheckHash) {
                $rootScope.intervalCheckHash = $interval(function () {
                    if ($rootScope.captureRunning) {
                        $rootScope.catchPMKID();
                        $rootScope.viewLog();
                    }
                }, 3000);
            }
        }
    });

    $scope.startAttack = function (bssid) {
        $rootScope.mac = bssid;
        $api.request({
            action: 'startAttack',
            module: 'PMKIDAttack',
            bssid: bssid
        }, function (response) {
            $rootScope.captureRunning = true;
            if (!$rootScope.intervalCheckHash) {
                $rootScope.intervalCheckHash = $interval(function () {
                    if ($rootScope.captureRunning) {
                        $rootScope.catchPMKID();
                        $rootScope.viewLog();
                    } else {
                        $rootScope.stopAttack();
                    }
                }, 2000);
            }
        });
    };

    $rootScope.catchPMKID = function () {
        $api.request({
            action: 'catchPMKID',
            module: 'PMKIDAttack'
        }, function (response) {
            if (response.success) {
                $rootScope.captureRunning = false;
            }
        });
    }
}]);

