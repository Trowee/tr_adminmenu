var vuexstore = Vuex.createStore({
    state: {
        showQuickMenu: false,
        showAdminPanel: false,
        players: [],
        onlineAdmins: [],
        logs: [],
        bans: [],
        staffMessages: [],
        myPermissions: {},
        myGroup: '',
        myName: '',
        myId: 0,
        myAvatar: null,
        serverName: 'Server',
        onlineCount: 0,
        maxPlayers: 64,
        notification: { type: false, text: false },
        notificationTimeout: false,
        selectedPlayer: null,
        selectedPlayerMugshot: null,
        selectedPlayerInventory: [],
        adminPanelKey: 0,
        selectedPlayerWarnings: [],
        selectedPlayerBans: [],
        showWarnModal: false,
        warnModalData: { reason: '', admin: '' },
        showDMReceiveModal: false,
        dmReceiveData: { message: '', admin: '' },
        showAnnouncementReceive: false,
        announcementData: { text: '', admin: '' },
        announcementTimeout: null,
        vehicles: [],
        weatherTypes: [],
        enabledSections: {},
        availableJobs: [],
        analytics: { currentPlayers: 0, peakPlayers: 0, totalBans: 0, activeBans: 0, totalKicks: 0, totalWarnings: 0, actionsToday: 0, actions7d: 0, categoryBreakdown: [], dailyCounts: [], adminLeaderboard: [], adminGroups: [], topPlayers: { richest: [], newest: [] }, weeklyStats: { bans: 0, kicks: 0, warns: 0 }, jobStats: [] },
        jobStats: [],
        consoleLogs: [],
        resources: [],
        availableGroups: [],
        offlinePlayers: [],
        selectedOfflinePlayer: null,
        locales: {},
    },
    mutations: {
        setShowQuickMenu(state, v) { state.showQuickMenu = v; },
        setShowAdminPanel(state, v) { state.showAdminPanel = v; },
        setPlayers(state, v) { state.players = v || []; state.onlineCount = (v || []).length; },
        setOnlineAdmins(state, v) { state.onlineAdmins = v || []; },
        setLogs(state, v) { state.logs = v || []; },
        setBans(state, v) { state.bans = v || []; },
        addStaffMessage(state, v) { state.staffMessages.push(v); },
        setMyPermissions(state, v) { state.myPermissions = v || {}; },
        setMyGroup(state, v) { state.myGroup = v; },
        setMyName(state, v) { state.myName = v; },
        setMyId(state, v) { state.myId = v; },
        setMyAvatar(state, v) { state.myAvatar = v; },
        setServerName(state, v) { state.serverName = v; },
        setOnlineCount(state, v) { state.onlineCount = v; },
        setMaxPlayers(state, v) { state.maxPlayers = v; },
        setSelectedPlayer(state, v) { state.selectedPlayer = v; },
        setSelectedPlayerMugshot(state, v) { state.selectedPlayerMugshot = v; },
        setSelectedPlayerInventory(state, v) { state.selectedPlayerInventory = v || []; },
        incrementAdminPanelKey(state) { state.adminPanelKey++; },
        setPlayerWarnings(state, v) { state.selectedPlayerWarnings = v || []; },
        setPlayerBans(state, v) { state.selectedPlayerBans = v || []; },
        setShowWarnModal(state, v) { state.showWarnModal = v; },
        setWarnModalData(state, v) { state.warnModalData = v; },
        setShowDMReceiveModal(state, v) { state.showDMReceiveModal = v; },
        setDMReceiveData(state, v) { state.dmReceiveData = v; },
        setShowAnnouncementReceive(state, v) { state.showAnnouncementReceive = v; },
        setAnnouncementData(state, v) {
            state.announcementData = v;
            if (v && state.showAnnouncementReceive) {
                if (state.announcementTimeout) clearTimeout(state.announcementTimeout);
                var duration = v.duration || 7000;
                state.announcementTimeout = setTimeout(() => {
                    state.showAnnouncementReceive = false;
                }, duration);
            }
        },
        setVehicles(state, v) { state.vehicles = v || []; },
        setEnabledSections(state, v) { state.enabledSections = v || {}; },
        setAllItems(state, v) { state.allItems = v || []; },
        setAvailableJobs(state, v) { state.availableJobs = v || []; },
        setAnalytics(state, v) {
            state.analytics = { ...state.analytics, ...v };
        },
        setTopPlayers(state, v) {
            state.analytics.topPlayers = v || { richest: [], newest: [] };
        },
        setWeeklyStats(state, v) {
            state.analytics.weeklyStats = v || { bans: 0, kicks: 0, warns: 0 };
        },
        setJobStats(state, v) {
            state.analytics.jobStats = v || [];
        },
        createNotification(state, payload) {
            clearTimeout(state.notificationTimeout);
            state.notification = { type: payload.type || 'info', text: payload.text };
            state.notificationTimeout = setTimeout(() => {
                state.notification = null;
            }, 3000);
        },
        setConsoleLogs(state, v) { state.consoleLogs = v || []; },
        addConsoleLog(state, v) {
            var formatted = v.replace(/\^([0-9])/g, (match, colorCode) => {
                var colors = ['#F0F0F0', '#EF4444', '#10B981', '#F59E0B', '#3B82F6', '#6366F1', '#8B5CF6', '#F0F0F0', '#9CA3AF', '#DB2777'];
                return '</span><span style="color:' + (colors[parseInt(colorCode)] || '#F0F0F0') + '">';
            });
            formatted = '<span>' + formatted + '</span>';
            state.consoleLogs.push(formatted);
        },
        setResources(state, v) { state.resources = v || []; },
        setAvailableGroups(state, v) { state.availableGroups = v || []; },
        setOfflinePlayers(state, v) { state.offlinePlayers = v || []; },
        setSelectedOfflinePlayer(state, v) { state.selectedOfflinePlayer = v; },
        setLocales(state, v) { state.locales = v || {}; },
    }
});
var QuickMenu = {
    template: '#quickmenu-template',
    computed: {
        players() { return this.$store.state.players; },
        serverName() { return this.$store.state.serverName; },
        myPermissions() { return this.$store.state.myPermissions; },
    },
    data() {
        return {
            idPopup: { show: false, action: '', inputId: '' },
            foundPlayer: null,
            announcementPopup: false,
            announcementText: '',
        };
    },
    methods: {
        closeMenu() {
            this.$store.commit('setShowQuickMenu', false);
            window.postNUI('closeQuickMenu');
        },
        doAction(action) { window.postNUI('quickAction', { action: action }); },
        openIdPopup(action) {
            this.idPopup = { show: true, action: action, inputId: '' };
            this.foundPlayer = null;
        },
        closeIdPopup() { this.idPopup = { show: false, action: '', inputId: '' }; this.foundPlayer = null; },
        lookupPlayer() {
            var id = parseInt(this.idPopup.inputId);
            if (!id) { this.foundPlayer = null; return; }
            this.foundPlayer = this.players.find(function (p) { return p.id === id; }) || null;
        },
        confirmAction() {
            if (!this.foundPlayer) return;
            var action = this.idPopup.action;
            if (action === 'kick') {
                window.postNUI('quickAction', { action: 'kick', targetId: this.foundPlayer.id, reason: 'Kicked by admin' });
            } else {
                window.postNUI('quickAction', { action: action, targetId: this.foundPlayer.id });
            }
            this.closeIdPopup();
        },
        openAnnouncementPopup() {
            this.announcementText = '';
            this.announcementPopup = true;
        },
        sendQMAnnouncement() {
            if (!this.announcementText) return;
            window.postNUI('sendAnnouncement', { message: this.announcementText });
            this.announcementPopup = false;
            this.announcementText = '';
        }
    }
};
var AdminPanel = {
    template: '#adminpanel-template',
    computed: {
        players() { return this.$store.state.players; },
        onlineAdmins() { return this.$store.state.onlineAdmins; },
        analytics() { return this.$store.state.analytics; },
        maxAdminActions() {
            var a = this.analytics.adminLeaderboard || [];
            return (a.length > 0 ? a[0].actions : 1) || 1;
        },
        donutTotal() {
            return (this.analytics.totalBans || 0) + (this.analytics.totalKicks || 0) + (this.analytics.totalWarnings || 0);
        },
        donutStyle() {
            var total = this.donutTotal || 1;
            var bans = (this.analytics.totalBans || 0) / total * 100;
            var kicks = (this.analytics.totalKicks || 0) / total * 100;
            var warns = (this.analytics.totalWarnings || 0) / total * 100;
            if (total === 0 || (bans === 0 && kicks === 0 && warns === 0)) {
                return { background: 'conic-gradient(rgba(255,255,255,0.06) 0% 100%)' };
            }
            var p1 = bans;
            var p2 = p1 + kicks;
            return { background: 'conic-gradient(#EF4444 0% ' + p1 + '%, #8B5CF6 ' + p1 + '% ' + p2 + '%, #06B6D4 ' + p2 + '% 100%)' };
        },
        capacityRingStyle() {
            var online = this.onlineCount || 0;
            var max = 64;
            var pct = Math.min(100, (online / max) * 100);
            var color = pct > 80 ? '#EF4444' : pct > 50 ? '#F59E0B' : '#10B981';
            return { background: 'conic-gradient(' + color + ' 0% ' + pct + '%, rgba(255,255,255,0.06) ' + pct + '% 100%)' };
        },
        logs() { return this.$store.state.logs; },
        bans() { return this.$store.state.bans; },
        staffMessages() { return this.$store.state.staffMessages; },
        vehicles() { return this.$store.state.vehicles; },
        myPermissions() { return this.$store.state.myPermissions; },
        myGroup() { return this.$store.state.myGroup; },
        myName() { return this.$store.state.myName; },
        myId() { return this.$store.state.myId; },
        myAvatar() { return this.$store.state.myAvatar; },
        onlineCount() { return this.$store.state.onlineCount; },
        maxPlayers() { return this.$store.state.maxPlayers; },
        serverName() { return this.$store.state.serverName; },
        selectedPlayer() { return this.$store.state.selectedPlayer; },
        selectedPlayerMugshot() { return this.$store.state.selectedPlayerMugshot; },
        selectedPlayerInventory() { return this.$store.state.selectedPlayerInventory; },
        selectedPlayerBans() { return this.$store.state.selectedPlayerBans; },
        selectedPlayerWarnings() { return this.$store.state.selectedPlayerWarnings; },
        availableJobs() { return this.$store.state.availableJobs; },
        showAnnouncementReceive() { return this.$store.state.showAnnouncementReceive; },
        announcementData() { return this.$store.state.announcementData; },
        showDMReceiveModal() { return this.$store.state.showDMReceiveModal; },
        dmReceiveData() { return this.$store.state.dmReceiveData; },
        consoleLogs() { return this.$store.state.consoleLogs; },
        resources() { return this.$store.state.resources; },
        availableGroups() { return this.$store.state.availableGroups; },
        offlinePlayers() { return this.$store.state.offlinePlayers; },
        selectedOfflinePlayer() { return this.$store.state.selectedOfflinePlayer; },
        filteredOfflinePlayers() {
            var self = this;
            var list = self.offlinePlayers || [];
            if (self.offlineSearch) {
                var q = self.offlineSearch.toLowerCase();
                list = list.filter(function (p) {
                    return (p.name && p.name.toLowerCase().includes(q)) ||
                        (p.identifier && p.identifier.toLowerCase().includes(q)) ||
                        (p.job && p.job.toLowerCase().includes(q)) ||
                        (p.group && p.group.toLowerCase().includes(q));
                });
            }
            var sort = self.offlineSort;
            if (sort === 'name') {
                list = list.slice().sort(function (a, b) { return (a.name || '').localeCompare(b.name || ''); });
            } else if (sort === 'cash') {
                list = list.slice().sort(function (a, b) { return (b.money || 0) - (a.money || 0); });
            } else if (sort === 'bank') {
                list = list.slice().sort(function (a, b) { return (b.bank || 0) - (a.bank || 0); });
            } else if (sort === 'job') {
                list = list.slice().sort(function (a, b) { return (a.job || '').localeCompare(b.job || ''); });
            }
            return list;
        },
        filteredOfflineJobs() {
            var self = this;
            var jobs = self.availableJobs || [];
            if (!Array.isArray(jobs)) jobs = [];
            if (!self.offlineJobSearch) return jobs.slice(0, 20);
            var q = self.offlineJobSearch.toLowerCase();
            return jobs.filter(function (j) {
                return (j.label && j.label.toLowerCase().includes(q)) || (j.name && j.name.toLowerCase().includes(q));
            }).slice(0, 20);
        },
        filteredResources() {
            var self = this;
            if (!self.resourceSearch) return self.resources;
            var q = self.resourceSearch.toLowerCase();
            return self.resources.filter(function (r) {
                return (r.name && r.name.toLowerCase().includes(q));
            });
        },
        offlineWealthChartData() {
            var list = this.offlinePlayers || [];
            if (!this.selectedOfflineId) return [];
            var playersWithWealth = list.map(p => {
                var w = (p.money || 0) + (p.bank || 0);
                return { identifier: p.identifier, name: p.name, wealth: w };
            });
            playersWithWealth.sort(function (a, b) { return b.wealth - a.wealth; });
            var top = playersWithWealth.slice(0, 40);
            var selIdx = playersWithWealth.findIndex(p => p.identifier === this.selectedOfflineId);
            if (selIdx >= 40) {
                top[39] = playersWithWealth[selIdx];
            }
            return top;
        },
        offlineAverages() {
            var list = this.offlinePlayers || [];
            if (list.length === 0) return { cash: 0, bank: 0, total: 0 };
            var totalCash = 0;
            var totalBank = 0;
            list.forEach(p => {
                totalCash += (p.money || 0);
                totalBank += (p.bank || 0);
            });
            return {
                cash: Math.round(totalCash / list.length),
                bank: Math.round(totalBank / list.length),
                total: Math.round((totalCash + totalBank) / list.length)
            };
        },
        offlineChartMax() {
            var avg = this.offlineAverages;
            var maxAvg = Math.max(avg.cash, avg.bank, avg.total);
            var max = maxAvg;
            var p = this.selectedOfflinePlayer;
            if (p) {
                var pTotal = (p.money || 0) + (p.bank || 0);
                max = Math.max(maxAvg, pTotal, p.money || 0, p.bank || 0);
            }
            return max || 1;
        },
        sections() {
            var s = this.$store.state.enabledSections;
            var p = this.$store.state.myPermissions || {};
            return {
                home: s.home !== false,
                players: s.players !== false,
                offline_players: s.offline_players !== false && p.offline_players,
                bans: s.bans !== false && p.ban,
                kick: s.kick !== false && p.kick,
                spectate: s.spectate !== false && p.spectate,
                logs: s.logs !== false && p.view_logs,
                admins: s.admins !== false,
                staffchat: s.staffchat !== false && p.staff_chat,
                vehicles: s.vehicles !== false && p.manage_vehicles,
                client_executor: s.client_executor !== false && p.client_executor,
                manage_resources: s.manage_resources !== false && p.manage_resources,
            };
        },
        allItems() { return this.$store.state.allItems; },
        filteredOfflineInventory() {
            var self = this;
            var items = (self.selectedOfflinePlayer && self.selectedOfflinePlayer.inventory) || [];
            var merged = {};
            items.forEach(i => {
                var key = i.name;
                if (!merged[key]) {
                    merged[key] = { ...i };
                } else {
                    merged[key].count += i.count;
                }
            });
            items = Object.values(merged);
            if (self.offlineInventorySearch) {
                var q = self.offlineInventorySearch.toLowerCase();
                items = items.filter(function (i) {
                    return (i.label && i.label.toLowerCase().includes(q)) || (i.name && i.name.toLowerCase().includes(q));
                });
            }
            if (self.offlineInventorySort && self.offlineInventorySort !== 'none') {
                items = items.sort((a, b) => {
                    if (self.offlineInventorySort === 'label_asc') return (a.label || a.name || '').localeCompare(b.label || b.name || '');
                    if (self.offlineInventorySort === 'label_desc') return (b.label || b.name || '').localeCompare(a.label || a.name || '');
                    if (self.offlineInventorySort === 'count_asc') return (a.count || 0) - (b.count || 0);
                    if (self.offlineInventorySort === 'count_desc') return (b.count || 0) - (a.count || 0);
                    return 0;
                });
            }
            return items;
        },
        filteredInventory() {
            var self = this;
            var items = self.selectedPlayerInventory || [];
            var merged = {};
            items.forEach(i => {
                var key = i.name;
                if (!merged[key]) {
                    merged[key] = { ...i };
                } else {
                    merged[key].count += i.count;
                }
            });
            items = Object.values(merged);
            if (self.inventorySearch) {
                var q = self.inventorySearch.toLowerCase();
                items = items.filter(function (i) {
                    return (i.label && i.label.toLowerCase().includes(q)) || (i.name && i.name.toLowerCase().includes(q));
                });
            }
            if (self.inventorySort && self.inventorySort !== 'none') {
                items = items.sort((a, b) => {
                    if (self.inventorySort === 'label_asc') return (a.label || a.name || '').localeCompare(b.label || b.name || '');
                    if (self.inventorySort === 'label_desc') return (b.label || b.name || '').localeCompare(a.label || a.name || '');
                    if (self.inventorySort === 'count_asc') return (a.count || 0) - (b.count || 0);
                    if (self.inventorySort === 'count_desc') return (b.count || 0) - (a.count || 0);
                    return 0;
                });
            }
            return items;
        },
        filteredAllItems() {
            var self = this;
            if (!self.itemSearch) return self.allItems;
            var q = self.itemSearch.toLowerCase();
            return self.allItems.filter(function (i) {
                return (i.label && i.label.toLowerCase().includes(q)) || (i.name && i.name.toLowerCase().includes(q));
            });
        },
        filteredOfflineAllItems() {
            var self = this;
            if (!self.offlineItemSearch) return self.allItems;
            var q = self.offlineItemSearch.toLowerCase();
            return self.allItems.filter(function (i) {
                return (i.label && i.label.toLowerCase().includes(q)) || (i.name && i.name.toLowerCase().includes(q));
            });
        },
        filteredPlayers() {
            var self = this;
            var list = self.players || [];
            if (self.playerSearchId) {
                var searchStr = String(self.playerSearchId).toLowerCase();
                list = list.filter(function (p) {
                    var isIdMatch = String(p.id).includes(searchStr);
                    var isNameMatch = p.name && p.name.toLowerCase().includes(searchStr);
                    var isPlayerNameMatch = p.playerName && p.playerName.toLowerCase().includes(searchStr);
                    var isJobMatch = p.job && p.job.toLowerCase().includes(searchStr);
                    var isIdentifierMatch = false;
                    if (p.identifiers) {
                        for (var k in p.identifiers) {
                            if (p.identifiers[k] && String(p.identifiers[k]).toLowerCase().includes(searchStr)) {
                                isIdentifierMatch = true;
                                break;
                            }
                        }
                    }
                    return isIdMatch || isNameMatch || isPlayerNameMatch || isJobMatch || isIdentifierMatch;
                });
            }
            var sort = self.playerSort;
            if (sort === 'name') {
                list = list.slice().sort(function (a, b) { return (a.name || '').localeCompare(b.name || ''); });
            } else if (sort === 'money') {
                list = list.slice().sort(function (a, b) {
                    var aTotal = (a.money || 0) + (a.bank || 0);
                    var bTotal = (b.money || 0) + (b.bank || 0);
                    return bTotal - aTotal;
                });
            } else if (sort === 'group') {
                var groupWeight = function (g) {
                    var rg = (g || '').toLowerCase();
                    if (rg === 'founder') return 100;
                    if (rg === 'owner') return 90;
                    if (rg === 'superadmin') return 80;
                    if (rg === 'admin') return 70;
                    if (rg === 'mod' || rg === 'moderator') return 60;
                    if (rg === 'helper') return 50;
                    if (rg === 'vip') return 40;
                    return 0;
                };
                list = list.slice().sort(function (a, b) { return groupWeight(b.group) - groupWeight(a.group); });
            } else if (sort === 'steam') {
                list = list.slice().sort(function (a, b) { return (a.playerName || '').localeCompare(b.playerName || ''); });
            } else if (sort === 'id') {
                list = list.slice().sort(function (a, b) { return a.id - b.id; });
            }
            return list;
        },
        filteredSpectatePlayers() {
            var self = this;
            if (!self.spectateSearch) return self.players;
            var searchStr = String(self.spectateSearch).toLowerCase();
            return self.players.filter(function (p) {
                var isIdMatch = String(p.id).includes(searchStr);
                var isNameMatch = p.name && p.name.toLowerCase().includes(searchStr);
                var isPlayerNameMatch = p.playerName && p.playerName.toLowerCase().includes(searchStr);
                return isIdMatch || isNameMatch || isPlayerNameMatch;
            });
        },
        filteredBans() {
            var self = this;
            if (!self.banSearch) return self.bans;
            var q = self.banSearch.toLowerCase();
            return self.bans.filter(function (b) {
                return (b.name && b.name.toLowerCase().includes(q)) || (b.identifier && b.identifier.toLowerCase().includes(q)) || (b.reason && b.reason.toLowerCase().includes(q));
            });
        },
        filteredLogs() {
            var self = this;
            var list = self.logs;
            if (self.logFilter !== 'all') {
                list = list.filter(function (l) { return l.category === self.logFilter; });
            }
            if (self.logAdminSearch) {
                var qa = self.logAdminSearch.toLowerCase();
                list = list.filter(function (l) { return l.admin_name && l.admin_name.toLowerCase().includes(qa); });
            }
            if (self.logTargetSearch) {
                var qt = self.logTargetSearch.toLowerCase();
                list = list.filter(function (l) { return l.target_name && l.target_name.toLowerCase().includes(qt); });
            }
            if (self.logActionSearch) {
                var qact = self.logActionSearch.toLowerCase();
                list = list.filter(function (l) { return (l.action && l.action.toLowerCase().includes(qact)) || (l.details && l.details.toLowerCase().includes(qact)); });
            }
            return list;
        },
        filteredVehicles() {
            var self = this;
            if (!self.vehicleSearch) return self.vehicles;
            var q = self.vehicleSearch.toLowerCase();
            return self.vehicles.filter(function (v) {
                return (v.plate && v.plate.toLowerCase().includes(q)) || (v.owner_name && v.owner_name.toLowerCase().includes(q)) || (v.owner && v.owner.toLowerCase().includes(q)) || (v.vehicle && v.vehicle.toLowerCase().includes(q));
            });
        },
        filteredJobs() {
            var self = this;
            var jobs = self.availableJobs || [];
            if (!Array.isArray(jobs)) jobs = [];
            if (!self.jobSearch) return jobs;
            var q = self.jobSearch.toLowerCase();
            return jobs.filter(function (j) {
                return (j.label && j.label.toLowerCase().includes(q)) || (j.name && j.name.toLowerCase().includes(q));
            });
        },
        jobChartStyle() {
            var jobs = this.analytics.jobStats || [];
            if (jobs.length === 0) return { background: 'conic-gradient(rgba(255,255,255,0.06) 0% 100%)', borderRadius: '50%', width: '100%', height: '100%' };
            var total = jobs.reduce(function (a, b) { return a + b.count; }, 0);
            var gradients = [];
            var current = 0;
            var colors = ['#10B981', '#3B82F6', '#F59E0B', '#EF4444', '#8B5CF6'];
            for (var i = 0; i < jobs.length; i++) {
                var job = jobs[i];
                var start = (current / total) * 100;
                var end = ((current + job.count) / total) * 100;
                gradients.push(colors[i % colors.length] + ' ' + start + '% ' + end + '%');
                current += job.count;
            }
            return {
                background: 'conic-gradient(' + gradients.join(', ') + ')',
                borderRadius: '50%',
                width: '100%',
                height: '100%'
            };
        },
        jobLegend() {
            var jobs = this.analytics.jobStats || [];
            var total = jobs.reduce(function (a, b) { return a + b.count; }, 0);
            var colors = ['#10B981', '#3B82F6', '#F59E0B', '#EF4444', '#8B5CF6'];
            return jobs.map(function (j, i) {
                return {
                    name: j.name,
                    count: j.count,
                    percent: total > 0 ? Math.round((j.count / total) * 100) : 0,
                    color: colors[i % colors.length]
                };
            });
        },
        kickPreviewPlayer() {
            var self = this;
            if (!self.kickForm.id) return null;
            var id = parseInt(self.kickForm.id);
            return self.players.find(function (p) { return p.id === id; }) || null;
        },
        spectatePreviewPlayer() {
            var self = this;
            if (!self.spectateSearch) return null;
            var id = parseInt(self.spectateSearch);
            if (isNaN(id)) return null;
            return self.players.find(function (p) { return p.id === id; }) || null;
        },
        currentTime() {
            var d = new Date();
            return d.getHours().toString().padStart(2, '0') + ':' + d.getMinutes().toString().padStart(2, '0');
        },
        banDurations() {
            return [
                { label: '1 Hour', seconds: 3600 },
                { label: '6 Hours', seconds: 21600 },
                { label: '12 Hours', seconds: 43200 },
                { label: '1 Day', seconds: 86400 },
                { label: '3 Days', seconds: 259200 },
                { label: '7 Days', seconds: 604800 },
                { label: '14 Days', seconds: 1209600 },
                { label: '30 Days', seconds: 2592000 },
                { label: 'Permanent', seconds: 0 },
            ];
        },
        logCategories() {
            return ['quickmenu', 'moderation', 'management', 'playerstate', 'vehicle', 'system'];
        },
    },
    data() {
        return {
            tab: 'home',
            selectedPlayerId: null,
            playerSearchId: '',
            playerSort: 'id',
            showIp: false,
            banSearch: '',
            logFilter: 'all',
            logAdminSearch: '',
            logTargetSearch: '',
            logActionSearch: '',
            vehicleSearch: '',
            mugshotLoading: false,
            chatInput: '',
            spectateId: '',
            activeActionModal: null,
            actionForm: { job: '', grade: 0, group: '', moneyType: 'money', amount: 0, itemName: '', itemLabel: '', itemCount: 1, itemMax: 1, dmMessage: '', warnReason: '' },
            itemSearch: '',
            offlineItemSearch: '',
            kickForm: { id: '', reason: '' },
            showKickModal: false,
            showKillModal: false,
            killTargetId: '',
            banForm: { targetId: null, name: '', reason: '', duration: 3600 },
            showSendAnnouncementModal: false,
            announcementText: '',
            showBanModal: false,
            showChangePlateModal: false,
            changePlateData: { oldPlate: '', newPlate: '' },
            showAddVehicleModal: false,
            addVehicleData: { playerId: '', model: '', plate: '' },
            jobSearch: '',
            selectedJob: null,
            selectedJobGrades: [],
            consoleInput: '',
            resourceSearch: '',
            profileTab: 'inventory',
            inventorySearch: '',
            inventorySort: 'none',
            spectateSearch: '',
            offlineSearch: '',
            offlineSort: 'name',
            selectedOfflineId: null,
            offlineActionModal: null,
            offlineActionForm: { job: '', grade: 0, group: '', moneyType: 'money', amount: 0, reason: '', duration: 3600, itemName: '', vehicleModel: '', plate: '', coords: { x: null, y: null, z: null } },
            offlineJobSearch: '',
            selectedOfflineJob: null,
            selectedOfflineJobGrades: [],
            offlineInventorySearch: '',
            offlineInventorySort: 'none',
            showScreenshotModal: false,
            screenshotImage: '',
        };
    },
    watch: {
        tab(newTab) {
            if (newTab === 'home') {
                this.refreshAnalytics();
            } else if (newTab === 'players') {
                window.postNUI('getPlayers');
            } else if (newTab === 'bans') {
                window.postNUI('getBans');
            } else if (newTab === 'logs') {
                window.postNUI('getLogs');
            } else if (newTab === 'admins') {
                window.postNUI('getOnlineAdmins');
            } else if (newTab === 'vehicles') {
                window.postNUI('getVehicles');
            } else if (newTab === 'client_executor') {
                this.$nextTick(() => {
                    if (this.$refs.consoleOutput) this.$refs.consoleOutput.scrollTop = this.$refs.consoleOutput.scrollHeight;
                });
            } else if (newTab === 'manage_resources') {
                window.postNUI('getResources');
            } else if (newTab === 'offline_players') {
                this.selectedOfflineId = null;
                this.$store.commit('setSelectedOfflinePlayer', null);
                window.postNUI('getOfflinePlayers');
                window.postNUI('getAllJobs');
                window.postNUI('getAvailableGroups');
            }
        },
        selectedPlayerMugshot(newVal) {
            this.mugshotLoading = false;
        }
    },
    mounted() {
        window.adminPanelInstance = this;
        window.postNUI('getPlayers');
        window.postNUI('getBans');
        window.postNUI('getLogs');
        window.postNUI('getOnlineAdmins');
        window.postNUI('getVehicles');
        window.postNUI('getAllItems');
        window.postNUI('getAllJobs');
        window.postNUI('getAnalytics');
        window.postNUI('getTopPlayers');
        window.postNUI('getWeeklyStats');
        window.postNUI('getJobStats');
        window.postNUI('getAvailableGroups');
        this.jobStatsInterval = setInterval(() => {
            if (this.tab === 'home') {
                window.postNUI('getJobStats');
            }
        }, 12000);
    },
    unmounted() {
        if (this.jobStatsInterval) {
            clearInterval(this.jobStatsInterval);
        }
    },
    methods: {
        goToPlayerProfile(serverId, identifier) {
            if (serverId) {
                this.tab = 'players';
                this.$nextTick(() => {
                    this.selectPlayer(serverId);
                });
            } else if (identifier) {
                this.tab = 'offline_players';
                this.$nextTick(() => {
                    this.selectOfflinePlayer(identifier);
                });
            }
        },
        closePanel() {
            this.$store.commit('setShowAdminPanel', false);
            window.postNUI('closeAdminPanel');
        },
        selectOfflinePlayer(identifier) {
            this.selectedOfflineId = identifier;
            this.offlineActionModal = null;
            this.$store.commit('setSelectedOfflinePlayer', null);
            window.postNUI('getOfflinePlayerData', { identifier: identifier });
        },
        refreshOfflinePlayer() {
            if (!this.selectedOfflineId) return;
            window.postNUI('getOfflinePlayerData', { identifier: this.selectedOfflineId });
        },
        selectOfflineJob(job) {
            this.selectedOfflineJob = job;
            this.offlineActionForm.job = job.name;
            this.offlineJobSearch = job.label;
            this.selectedOfflineJobGrades = Object.values(job.grades || {}).sort((a, b) => a.grade - b.grade);
            this.offlineActionForm.grade = '';
        },
        selectOfflineGrade(grade) { this.offlineActionForm.grade = grade.grade; },
        offlineDoSetJob() {
            if (!this.offlineActionForm.job || !this.selectedOfflineId) return;
            window.postNUI('offlinePlayerAction', { action: 'setjob', identifier: this.selectedOfflineId, job: this.offlineActionForm.job, grade: parseInt(this.offlineActionForm.grade) || 0 });
            this.offlineActionModal = null;
            this.offlineActionForm.job = ''; this.offlineActionForm.grade = 0;
            setTimeout(this.refreshOfflinePlayer, 500);
        },
        offlineDoSetGroup() {
            if (!this.offlineActionForm.group || !this.selectedOfflineId) return;
            window.postNUI('offlinePlayerAction', { action: 'setgroup', identifier: this.selectedOfflineId, group: this.offlineActionForm.group });
            this.offlineActionModal = null;
            this.offlineActionForm.group = '';
            setTimeout(this.refreshOfflinePlayer, 500);
        },
        offlineDoSetMoney() {
            if (!this.selectedOfflineId) return;
            window.postNUI('offlinePlayerAction', { action: 'setmoney', identifier: this.selectedOfflineId, moneyType: this.offlineActionForm.moneyType, amount: parseInt(this.offlineActionForm.amount) || 0 });
            this.offlineActionModal = null;
            this.offlineActionForm.amount = 0;
            setTimeout(this.refreshOfflinePlayer, 500);
        },
        offlineDoRemoveMoney() {
            if (!this.selectedOfflineId) return;
            window.postNUI('offlinePlayerAction', { action: 'removemoney', identifier: this.selectedOfflineId, moneyType: this.offlineActionForm.moneyType, amount: parseInt(this.offlineActionForm.amount) || 0 });
            this.offlineActionModal = null;
            this.offlineActionForm.amount = 0;
            setTimeout(this.refreshOfflinePlayer, 500);
        },
        offlineDoBan() {
            if (!this.selectedOfflineId || !this.offlineActionForm.reason) return;
            window.postNUI('offlineBan', { identifier: this.selectedOfflineId, reason: this.offlineActionForm.reason, duration: this.offlineActionForm.duration });
            this.offlineActionModal = null;
            this.offlineActionForm.reason = '';
            setTimeout(this.refreshOfflinePlayer, 500);
        },
        offlineDoWarn() {
            if (!this.selectedOfflineId || !this.offlineActionForm.reason) return;
            window.postNUI('offlineWarn', { identifier: this.selectedOfflineId, reason: this.offlineActionForm.reason });
            this.offlineActionModal = null;
            this.offlineActionForm.reason = '';
            setTimeout(this.refreshOfflinePlayer, 500);
        },
        offlineDoGiveItem() {
            if (!this.selectedOfflineId || !this.offlineActionForm.itemName || !this.offlineActionForm.amount) return;
            window.postNUI('offlinePlayerAction', { action: 'giveitem', identifier: this.selectedOfflineId, itemName: this.offlineActionForm.itemName, amount: parseInt(this.offlineActionForm.amount) });
            this.offlineActionModal = null;
            this.offlineActionForm.itemName = ''; this.offlineActionForm.amount = 0;
            setTimeout(this.refreshOfflinePlayer, 500);
        },
        offlineDoSpawnVehicle() {
            if (!this.selectedOfflineId || !this.offlineActionForm.vehicleModel) return;
            window.postNUI('offlinePlayerAction', {
                action: 'spawnvehicle',
                identifier: this.selectedOfflineId,
                model: this.offlineActionForm.vehicleModel,
                plate: this.offlineActionForm.plate
            });
            this.offlineActionModal = null;
            this.offlineActionForm.vehicleModel = '';
            this.offlineActionForm.plate = '';
            setTimeout(this.refreshOfflinePlayer, 500);
        },
        async getAdminPos() {
            try {
                const data = await window.postNUI('getAdminPos');
                if (data && data.x !== undefined) {
                    this.offlineActionForm.coords.x = Number(data.x.toFixed(2));
                    this.offlineActionForm.coords.y = Number(data.y.toFixed(2));
                    this.offlineActionForm.coords.z = Number(data.z.toFixed(2));
                }
            } catch (e) { }
        },
        offlineDoSetPos() {
            if (this.offlineActionForm.coords.x === null) return;
            window.postNUI('offlinePlayerAction', { action: 'setpos', identifier: this.selectedOfflineId, coords: this.offlineActionForm.coords });
            this.offlineActionModal = null;
            this.offlineActionForm.coords = { x: null, y: null, z: null };
            setTimeout(this.refreshOfflinePlayer, 500);
        },
        offlineRemoveItemPrompt(item) {
            this.offlineActionForm.itemName = item.name || item.label;
            this.offlineActionForm.itemLabel = item.label || item.name;
            this.offlineActionForm.itemMax = item.count;
            this.offlineActionForm.amount = 1;
            this.offlineActionModal = 'removeitem';
        },
        offlineDoRemoveItem() {
            if (!this.offlineActionForm.itemName || this.offlineActionForm.amount <= 0) return;
            window.postNUI('offlinePlayerAction', {
                action: 'removeitem',
                identifier: this.selectedOfflineId,
                item: this.offlineActionForm.itemName,
                count: this.offlineActionForm.amount
            });
            this.offlineActionModal = null;
            this.selectedOfflineId = null;
            this.$store.commit('setSelectedOfflinePlayer', null);
            setTimeout(() => { window.postNUI('getOfflinePlayers'); }, 500);
        },
        copyAllIdentifiers() {
            const identifiers = this.$store.state.selectedOfflinePlayer?.identifiers || [];
            if (identifiers.length === 0) {
                this.$store.commit('createNotification', { type: 'error', text: 'No identifiers to copy!' });
                return;
            }
            const textToCopy = identifiers.join('\n');
            var ta = document.createElement("textarea");
            ta.value = textToCopy;
            ta.setAttribute('readonly', '');
            ta.style.position = 'absolute';
            ta.style.left = '-9999px';
            document.body.appendChild(ta);
            ta.select();
            ta.setSelectionRange(0, 99999);
            try {
                document.execCommand("copy");
                this.$store.commit('createNotification', { type: 'success', text: 'All identifiers copied to clipboard!' });
            } catch (err) {
                this.$store.commit('createNotification', { type: 'error', text: 'Failed to copy identifiers.' });
            }
            document.body.removeChild(ta);
        },
        formatSex(sex) {
            if (!sex) return 'N/A';
            if (sex.toLowerCase() === 'm') return 'Male';
            if (sex.toLowerCase() === 'f') return 'Female';
            return sex;
        },
        formatPosition(pos) {
            if (!pos) return 'N/A';
            try {
                let p = typeof pos === 'string' ? JSON.parse(pos) : pos;
                if (p && p.x !== undefined && p.y !== undefined && p.z !== undefined) {
                    return 'vec3(' + p.x.toFixed(2) + ', ' + p.y.toFixed(2) + ', ' + p.z.toFixed(2) + ')';
                }
            } catch (e) { }
            return String(pos);
        },
        getChartHeight(value, max) {
            if (!max || max <= 0) return 0;
            let val = (value / max) * 100;
            return Math.min(Math.max(val, 5), 100);
        },
        doAction(action) { window.postNUI('adminAction', { action: action }); },
        formatNumber(num) {
            if (num == null) return '0';
            return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
        },
        refreshAnalytics() { window.postNUI('getAnalytics'); window.postNUI('getTopPlayers'); window.postNUI('getWeeklyStats'); window.postNUI('getJobStats'); window.postNUI('getOnlineAdmins'); window.postNUI('getPlayers'); },
        formatDay(day) {
            if (!day) return '';
            if (typeof day === 'string') return day.length > 5 ? day.substring(5) : day;
            try { var d = new Date(day); if (!isNaN(d.getTime())) return (d.getMonth() + 1).toString().padStart(2, '0') + '-' + d.getDate().toString().padStart(2, '0'); } catch (e) { }
            return String(day);
        },
        formatDuty(mins) {
            if (!mins || mins <= 0) return '0m';
            var h = Math.floor(mins / 60);
            var m = mins % 60;
            return (h > 0 ? h + 'h ' : '') + m + 'm';
        },
        formatPlaytime(mins) {
            if (!mins || Number(mins) <= 0) return '0h 0m';
            var totalMins = Number(mins);
            var h = Math.floor(totalMins / 60);
            var m = totalMins % 60;
            return h + 'h ' + m + 'm';
        },
        formatDateFull(dateStr) {
            if (!dateStr || dateStr === 'N/A') return 'N/A';
            try {
                var d = new Date(dateStr);
                if (isNaN(d.getTime())) return String(dateStr);
                return d.toLocaleDateString() + ' ' + d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            } catch (e) { return String(dateStr); }
        },
        openKickPrompt() {
            this.kickForm = { id: '', reason: '' };
            this.showKickModal = true;
        },
        openKillPrompt() {
            this.killTargetId = '';
            this.showKillModal = true;
        },
        doKillAction() {
            if (!this.killTargetId) return;
            window.postNUI('quickAction', { action: 'kill', targetId: parseInt(this.killTargetId) });
            this.showKillModal = false;
            this.killTargetId = '';
        },
        selectPlayer(id) {
            this.selectedPlayerId = id;
            this.activeActionModal = null;
            this.profileTab = 'inventory';
            this.inventorySearch = '';
            this.$store.commit('setSelectedPlayer', null);
            this.$store.commit('setSelectedPlayerMugshot', null);
            this.$store.commit('setSelectedPlayerInventory', []);
            this.$store.commit('setSelectedPlayerInventory', []);
            this.mugshotLoading = true;
            window.postNUI('getPlayerData', { id: id, withMugshot: true });
            window.postNUI('getPlayerInventory', { id: id });
            window.postNUI('getWarnings', { targetId: id });
            window.postNUI('getPlayerBans', { targetId: id });
        },
        refreshSelectedPlayer() {
            if (!this.selectedPlayerId) return;
            window.postNUI('getPlayerData', { id: this.selectedPlayerId, withMugshot: false });
            window.postNUI('getPlayerInventory', { id: this.selectedPlayerId });
            window.postNUI('getWarnings', { targetId: this.selectedPlayerId });
            window.postNUI('getPlayerBans', { targetId: this.selectedPlayerId });
        },
        playerAction(action) {
            if (!this.selectedPlayerId) return;
            window.postNUI('playerAction', { action: action, targetId: this.selectedPlayerId });
            setTimeout(this.refreshSelectedPlayer, 500);
        },
        takeScreenshot() {
            if (!this.selectedPlayerId) return;
            this.screenshotImage = '';
            this.showScreenshotModal = true;
            window.postNUI('takeScreenshot', { targetId: this.selectedPlayerId });
        },
        openWarnPrompt() {
            this.actionForm.warnReason = '';
            this.activeActionModal = 'warn';
        },
        doWarn() {
            if (!this.actionForm.warnReason) return;
            window.postNUI('warnPlayer', { targetId: this.selectedPlayerId, reason: this.actionForm.warnReason });
            this.activeActionModal = null;
            this.actionForm.warnReason = '';
            setTimeout(this.refreshSelectedPlayer, 500);
        },
        closeWarnModal() { this.$store.commit('setShowWarnModal', false); },
        closeDMReceiveModal() { this.$store.commit('setShowDMReceiveModal', false); },
        openKickModal(player) {
            this.kickForm = { id: player.id, reason: '' };
            this.showKickModal = true;
        },
        openBanModal(player) {
            this.banForm = { targetId: player.id, name: player.name, reason: '', duration: 3600 };
            this.showBanModal = true;
        },
        confirmBan() {
            if (!this.banForm.reason) return;
            window.postNUI('banPlayer', { targetId: this.banForm.targetId, duration: this.banForm.duration, reason: this.banForm.reason });
            this.showBanModal = false;
            this.banForm = { targetId: null, name: '', reason: '', duration: 3600 };
        },
        doKick() {
            if (!this.kickForm.id || !this.kickForm.reason) return;
            window.postNUI('kickPlayer', { targetId: parseInt(this.kickForm.id), reason: this.kickForm.reason });
            this.kickForm = { id: '', reason: '' };
            this.showKickModal = false;
        },
        unbanPlayer(banId) { window.postNUI('unbanPlayer', { banId: banId }); },
        sendAnnouncement() {
            if (!this.announcementText) return;
            window.postNUI('sendAnnouncement', { text: this.announcementText });
            this.announcementText = '';
            this.showSendAnnouncementModal = false;
        },
        sendChatMessage() {
            if (!this.chatInput.trim()) return;
            window.postNUI('sendStaffChat', { text: this.chatInput });
            this.chatInput = '';
        },
        refreshLogs() { window.postNUI('getLogs'); },
        refreshLogs() { window.postNUI('getLogs'); },
        refreshLogs() { window.postNUI('getLogs'); },
        refreshVehicles() { window.postNUI('getVehicles'); },
        fetchJobs() {
            window.postNUI('getAllJobs');
        },
        selectJob(job) {
            this.selectedJob = job;
            this.actionForm.job = job.name;
            this.jobSearch = job.label;
            this.selectedJobGrades = Object.values(job.grades || {}).sort((a, b) => a.grade - b.grade);
            this.actionForm.grade = '';
        },
        selectGrade(grade) { this.actionForm.grade = grade.grade; },
        doSetJob() {
            if (!this.actionForm.job) return;
            window.postNUI('playerAction', { action: 'setjob', targetId: this.selectedPlayerId, job: this.actionForm.job, grade: parseInt(this.actionForm.grade) || 0 });
            this.activeActionModal = null;
            this.actionForm.job = ''; this.actionForm.grade = 0;
            setTimeout(this.refreshSelectedPlayer, 500);
        },
        doSetGroup() {
            if (!this.actionForm.group) return;
            window.postNUI('playerAction', { action: 'setgroup', targetId: this.selectedPlayerId, group: this.actionForm.group });
            this.activeActionModal = null;
            this.actionForm.group = '';
            setTimeout(this.refreshSelectedPlayer, 500);
        },
        doSetMoney() {
            window.postNUI('playerAction', { action: 'setmoney', targetId: this.selectedPlayerId, moneyType: this.actionForm.moneyType, amount: parseInt(this.actionForm.amount) || 0 });
            this.activeActionModal = null;
            this.actionForm.amount = 0;
            setTimeout(this.refreshSelectedPlayer, 500);
        },
        doRemoveMoney() {
            window.postNUI('playerAction', { action: 'removemoney', targetId: this.selectedPlayerId, moneyType: this.actionForm.moneyType, amount: parseInt(this.actionForm.amount) || 0 });
            this.activeActionModal = null;
            this.actionForm.amount = 0;
            setTimeout(this.refreshSelectedPlayer, 500);
        },
        copyToClipboard(text) {
            var ta = document.createElement("textarea");
            ta.value = text;
            ta.setAttribute('readonly', '');
            ta.style.position = 'absolute';
            ta.style.left = '-9999px';
            document.body.appendChild(ta);
            ta.select();
            ta.setSelectionRange(0, 99999);
            try {
                document.execCommand("copy");
                this.$store.commit('createNotification', { type: 'success', text: 'Copied to clipboard!' });
            } catch (e) {
                this.$store.commit('createNotification', { type: 'error', text: 'Failed to copy.' });
            }
            document.body.removeChild(ta);
        },
        copyAllIdentifiers() {
            var ids = this.selectedPlayer.identifiers || {};
            var text = "```\n";
            for (var key in ids) {
                text += key + ": " + ids[key] + "\n";
            }
            text += "```";
            this.copyToClipboard(text);
        },
        doGiveItem() {
            if (!this.actionForm.itemName) return;
            window.postNUI('playerAction', { action: 'giveitem', targetId: this.selectedPlayerId, itemName: this.actionForm.itemName, itemCount: parseInt(this.actionForm.itemCount) || 1 });
            this.activeActionModal = null;
            this.actionForm.itemName = ''; this.actionForm.itemCount = 1;
            setTimeout(this.refreshSelectedPlayer, 500);
        },
        removeItemPrompt(item) {
            this.actionForm.itemName = item.name;
            this.actionForm.itemLabel = item.label || item.name;
            this.actionForm.itemMax = item.count;
            this.actionForm.itemCount = item.count;
            this.activeActionModal = 'removeitem_confirm';
        },
        doRemoveItemConfirm() {
            window.postNUI('playerAction', { action: 'removeitem', targetId: this.selectedPlayerId, itemName: this.actionForm.itemName, itemCount: parseInt(this.actionForm.itemCount) || 1 });
            this.activeActionModal = null;
            this.actionForm.itemName = ''; this.actionForm.itemCount = 1;
            setTimeout(this.refreshSelectedPlayer, 500);
        },
        selectItem(item) {
            this.actionForm.itemName = item.name;
        },
        selectOfflineItem(item) {
            this.offlineActionForm.itemName = item.name;
        },
        doSendDM() {
            if (!this.actionForm.dmMessage) return;
            window.postNUI('playerAction', { action: 'senddm', targetId: this.selectedPlayerId, message: this.actionForm.dmMessage });
            this.activeActionModal = null;
            this.actionForm.dmMessage = '';
        },
        openChangePlateModal(vehicle) {
            this.changePlateData = { oldPlate: vehicle.plate, newPlate: '' };
            this.showChangePlateModal = true;
        },
        doChangePlate() {
            if (!this.changePlateData.newPlate) return;
            window.postNUI('changePlate', { oldPlate: this.changePlateData.oldPlate, newPlate: this.changePlateData.newPlate });
            this.showChangePlateModal = false;
        },
        removeVehicle(vehicle) {
            window.postNUI('removeVehicle', { plate: vehicle.plate });
            setTimeout(this.refreshVehicles, 500);
        },
        doAddVehicle() {
            if (!this.addVehicleData.playerId || !this.addVehicleData.model || !this.addVehicleData.plate) return;
            window.postNUI('addVehicle', { playerId: parseInt(this.addVehicleData.playerId), model: this.addVehicleData.model, plate: this.addVehicleData.plate });
            this.showAddVehicleModal = false;
            this.addVehicleData = { playerId: '', model: '', plate: '' };
        },
        formatNumber(n) { return Number(n).toLocaleString(); },
        formatExpire(ts) {
            if (!ts || ts === 0) return 'Permanent';
            var d = new Date(ts * 1000);
            return d.toLocaleDateString() + ' ' + d.toLocaleTimeString();
        },
        formatTimestamp(ts) {
            if (!ts || ts === 0) return 'Permanent';
            if (typeof ts === 'number') return new Date(ts * 1000).toLocaleString();
            if (typeof ts === 'string') {
                if (ts.indexOf('T') === -1) ts = ts.replace(' ', 'T');
                var d = new Date(ts);
                return isNaN(d.getTime()) ? ts : d.toLocaleString();
            }
            return ts;
        },
        getAdminColor(group) {
            var colors = { admin: '#3B82F6', superadmin: '#8B5CF6', developer: '#EF4444' };
            return colors[group] || '#3B82F6';
        },
        getLogIconStyle(category) {
            var colors = { ban: '#EF4444', kick: '#F59E0B', teleport: '#3B82F6', spawn: '#8B5CF6', kill: '#EF4444', heal: '#10B981', revive: '#06B6D4', spectate: '#6366F1', vehicle: '#F59E0B', inventory: '#8B5CF6', announcement: '#3B82F6', freeze: '#06B6D4', money: '#10B981', item: '#F59E0B', job: '#8B5CF6', group: '#6366F1', weather: '#06B6D4', report: '#F59E0B', dm: '#3B82F6' };
            var c = colors[category] || '#3B82F6';
            return 'background:' + c + '1a;color:' + c;
        },
        getLogIcon(category) {
            var icons = { ban: 'fa-ban', kick: 'fa-user-slash', teleport: 'fa-map-marker-alt', spawn: 'fa-car', kill: 'fa-skull', heal: 'fa-heart', revive: 'fa-heartbeat', spectate: 'fa-eye', vehicle: 'fa-car', inventory: 'fa-box', announcement: 'fa-bullhorn', freeze: 'fa-snowflake', money: 'fa-dollar-sign', item: 'fa-box-open', job: 'fa-briefcase', group: 'fa-users-cog', weather: 'fa-cloud-sun', report: 'fa-exclamation-circle', dm: 'fa-envelope' };
            return icons[category] || 'fa-info-circle';
        },
        getLogActionLabel(action) {
            if (!action) return '';
            var locales = this.$store.state.locales || {};
            var key = 'log_' + action.toLowerCase().replace(/\s+/g, '_');
            if (locales[key]) return locales[key];
            return action.replace(/_/g, ' ').replace(/\b\w/g, function (l) { return l.toUpperCase(); });
        },
        formatPlaytime(minutes) {
            if (!minutes || minutes <= 0) return '0h';
            var h = Math.floor(minutes / 60);
            var m = minutes % 60;
            if (h > 0 && m > 0) return h + 'h ' + m + 'm';
            if (h > 0) return h + 'h';
            return m + 'm';
        },
        doSpectate() {
            if (!this.spectateSearch) return;
            var id = parseInt(this.spectateSearch);
            if (isNaN(id)) return;
            window.postNUI('playerAction', { action: 'spectate', targetId: id });
            this.spectateSearch = '';
        },
        isBanActive(ban) {
            if (ban.unbanned_by) return false;
            if (ban.expire === 0) return true;
            return ban.expire > Math.floor(Date.now() / 1000);
        },
        formatDateSeconds(ts) {
            if (!ts) return '';
            var d = new Date(ts * 1000);
            return d.toLocaleDateString() + ' ' + d.toLocaleTimeString();
        },
        executeClientCode() {
            if (!this.consoleInput) return;
            window.postNUI('executeClientCode', { code: this.consoleInput });
            this.$store.commit('addConsoleLog', '> ' + this.consoleInput);
            this.consoleInput = '';
            this.$nextTick(() => {
                if (this.$refs.consoleOutput) this.$refs.consoleOutput.scrollTop = this.$refs.consoleOutput.scrollHeight;
            });
        },
        clearConsole() {
            this.$store.commit('setConsoleLogs', []);
        },
        fetchResources() {
            window.postNUI('getResources');
        },
        manageResource(name, action) {
            window.postNUI('manageResource', { name: name, action: action });
            setTimeout(this.fetchResources, 500);
        },
        formatColor(text) {
            if (!text) return '';
            var formatted = text.replace(/\^([0-9])/g, (match, colorCode) => {
                var colors = ['#F0F0F0', '#EF4444', '#10B981', '#F59E0B', '#3B82F6', '#6366F1', '#8B5CF6', '#F0F0F0', '#9CA3AF', '#DB2777'];
                return '</span><span style="color:' + (colors[parseInt(colorCode)] || '#F0F0F0') + '">';
            });
            return '<span>' + formatted + '</span>';
        }
    }
};
var app = Vue.createApp({
    data() {
        return {
        };
    },
    computed: {
        filteredJobs() {
            var self = this;
            if (!self.jobSearch) return self.availableJobs;
            var q = self.jobSearch.toLowerCase();
            var jobs = Array.isArray(self.availableJobs) ? self.availableJobs : Object.values(self.availableJobs);
            return jobs.filter(function (j) {
                return (j.label && j.label.toLowerCase().includes(q)) || (j.name && j.name.toLowerCase().includes(q));
            });
        },
        showQuickMenu() { return this.$store.state.showQuickMenu; },
        showAdminPanel() { return this.$store.state.showAdminPanel; },
        adminPanelKey() { return this.$store.state.adminPanelKey; },
        notification() { return this.$store.state.notification; },
        showWarnModal() { return this.$store.state.showWarnModal; },
        warnModalData() { return this.$store.state.warnModalData; },
        showDMReceiveModal() { return this.$store.state.showDMReceiveModal; },
        dmReceiveData() { return this.$store.state.dmReceiveData; },
        showAnnouncementReceive() { return this.$store.state.showAnnouncementReceive; },
        announcementData() { return this.$store.state.announcementData; },
    },
    methods: {
        closeDMReceiveModal() {
            vuexstore.commit('setShowDMReceiveModal', false);
            window.postNUI('closeDMReceiveModal');
        },
        closeWarnModal() {
            vuexstore.commit('setShowWarnModal', false);
            window.postNUI('closeWarnModal');
        },
        closeAnnouncementReceive() {
            vuexstore.commit('setShowAnnouncementReceive', false);
            window.postNUI('closeAnnouncementReceiveModal');
        },
        fetchJobs() {
            window.postNUI('getAllJobs');
        },
        selectJob(job) {
            this.selectedJob = job;
            this.actionForm.job = job.name;
            this.selectedJobGrades = Object.values(job.grades || {}).sort((a, b) => a.grade - b.grade);
            this.actionForm.grade = '';
        },
        selectGrade(grade) {
            this.actionForm.grade = grade.grade;
        },
    }
});
app.use(vuexstore);
app.mixin({
    methods: {
        t(key) {
            var locales = this.$store.state.locales;
            if (locales && locales[key] !== undefined) return locales[key];
            return key;
        }
    }
});
app.component('quickmenu', QuickMenu);
app.component('adminpanel', AdminPanel);
app.mount('#app');
document.getElementById('app').style.display = '';
document.getElementById('app').style.display = '';
window.addEventListener('message', function (event) {
    var data = event.data;
    if (!data || !data.action) return;
    var action = data.action;
    var payload = data.payload;
    switch (action) {
        case 'openQuickMenu':
            vuexstore.commit('setShowQuickMenu', true);
            break;
        case 'closeQuickMenu':
            vuexstore.commit('setShowQuickMenu', false);
            break;
        case 'openAdminPanel':
            vuexstore.commit('setShowAdminPanel', true);
            vuexstore.commit('incrementAdminPanelKey');
            break;
        case 'closeAdminPanel':
            vuexstore.commit('setShowAdminPanel', false);
            break;
        case 'openQuickMenu':
            vuexstore.commit('setShowQuickMenu', true);
            break;
        case 'closeQuickMenu':
            vuexstore.commit('setShowQuickMenu', false);
            break;
        case 'setPlayers':
            vuexstore.commit('setPlayers', payload);
            break;
        case 'setOnlineAdmins':
            vuexstore.commit('setOnlineAdmins', payload);
            break;
        case 'setLogs':
            vuexstore.commit('setLogs', payload);
            break;
        case 'setBans':
            vuexstore.commit('setBans', payload);
            break;
        case 'addStaffMessage':
            vuexstore.commit('addStaffMessage', payload);
            break;
        case 'setMyPermissions':
            vuexstore.commit('setMyPermissions', payload);
            break;
        case 'setMyGroup':
            vuexstore.commit('setMyGroup', payload);
            break;
        case 'setMyName':
            vuexstore.commit('setMyName', payload);
            break;
        case 'setMyId':
            vuexstore.commit('setMyId', payload);
            break;
        case 'setMyAvatar':
            vuexstore.commit('setMyAvatar', payload);
            break;
        case 'setServerName':
            vuexstore.commit('setServerName', payload);
            break;
        case 'setOnlineCount':
            vuexstore.commit('setOnlineCount', payload);
            break;
        case 'setMaxPlayers':
            vuexstore.commit('setMaxPlayers', payload);
            break;
        case 'setSelectedPlayer':
            vuexstore.commit('setSelectedPlayer', payload);
            break;
        case 'setSelectedPlayerMugshot':
            vuexstore.commit('setSelectedPlayerMugshot', payload);
            break;
        case 'setSelectedPlayerInventory':
            vuexstore.commit('setSelectedPlayerInventory', payload);
            break;
        case 'setVehicles':
            vuexstore.commit('setVehicles', payload);
            break;
        case 'setEnabledSections':
            vuexstore.commit('setEnabledSections', payload);
            break;
        case 'setAllItems':
            vuexstore.commit('setAllItems', payload);
            break;
        case 'createNotification':
            vuexstore.commit('createNotification', payload);
            break;
        case 'setPlayerWarnings':
            vuexstore.commit('setPlayerWarnings', payload);
            break;
        case 'setPlayerBans':
            vuexstore.commit('setPlayerBans', payload);
            break;
        case 'openWarn':
            vuexstore.commit('setWarnModalData', payload);
            vuexstore.commit('setShowWarnModal', true);
            break;
        case 'openDM':
            vuexstore.commit('setDMReceiveData', payload);
            vuexstore.commit('setShowDMReceiveModal', true);
            break;
        case 'openAnnouncement':
            vuexstore.commit('setAnnouncementData', payload);
            vuexstore.commit('setShowAnnouncementReceive', true);
            setTimeout(() => {
                vuexstore.commit('setShowAnnouncementReceive', false);
            }, 8000);
            break;
        case 'receiveAllJobs':
            vuexstore.commit('setAvailableJobs', payload);
            break;
        case 'setAvailableGroups':
            vuexstore.commit('setAvailableGroups', payload);
            break;
        case 'receiveAnalytics':
            vuexstore.commit('setAnalytics', payload);
            break;
        case 'setTopPlayers':
            vuexstore.commit('setTopPlayers', payload);
            break;
        case 'setWeeklyStats':
            vuexstore.commit('setWeeklyStats', payload);
            break;
        case 'setJobStats':
            vuexstore.commit('setJobStats', payload);
            break;
        case 'setConsoleLogs':
            vuexstore.commit('setConsoleLogs', payload);
            break;
        case 'addConsoleLog':
            vuexstore.commit('addConsoleLog', payload);
            break;
        case 'setResources':
            vuexstore.commit('setResources', payload);
            break;
        case 'setOfflinePlayers':
            vuexstore.commit('setOfflinePlayers', payload);
            break;
        case 'setSelectedOfflinePlayer':
            vuexstore.commit('setSelectedOfflinePlayer', payload);
            break;
        case 'setLocales':
            vuexstore.commit('setLocales', payload);
            break;
        case 'showControlsOverlay':
            (function () {
                var el = document.getElementById('controls-overlay');
                var modeEl = document.getElementById('controls-overlay-mode');
                var keysEl = document.getElementById('controls-overlay-keys');
                if (!el || !modeEl || !keysEl) return;
                el.style.display = 'block';
                var kbd = function (key, accent) {
                    var bg = accent ? 'rgba(239,68,68,0.2)' : 'rgba(59,130,246,0.15)';
                    var clr = accent ? '#FCA5A5' : '#93C5FD';
                    var border = accent ? 'rgba(239,68,68,0.3)' : 'rgba(59,130,246,0.25)';
                    return '<kbd style="background:' + bg + ';padding:3px 8px;border-radius:5px;font-size:10px;font-weight:600;color:' + clr + ';border:1px solid ' + border + ';font-family:inherit;">' + key + '</kbd>';
                };
                var item = function (key, label, accent) {
                    return '<span style="display:flex;align-items:center;gap:5px;white-space:nowrap;">' + kbd(key, accent) + ' <span style="color:rgba(255,255,255,0.55);font-size:11px;">' + label + '</span></span>';
                };
                if (payload.mode === 'spectate') {
                    modeEl.innerHTML = '<i class="fas fa-eye" style="color:#60A5FA;"></i> <span style="color:#60A5FA;">SPECTATING</span>' + (payload.targetId ? ' <span style="color:rgba(255,255,255,0.4);font-weight:400;">ID: ' + payload.targetId + '</span>' : '');
                    keysEl.innerHTML = item('\u2190', 'Prev') + item('\u2192', 'Next') + item('Backspace', 'Exit', true);
                } else if (payload.mode === 'noclip') {
                    modeEl.innerHTML = '<i class="fas fa-ghost" style="color:#A78BFA;"></i> <span style="color:#A78BFA;">NOCLIP</span>';
                    keysEl.innerHTML = item('W A S D', 'Move') + item('E / Q', 'Up / Down') + item('Shift', 'Speed') + item('Backspace', 'Exit', true);
                }
            })();
            break;
        case 'hideControlsOverlay':
            (function () {
                var el = document.getElementById('controls-overlay');
                if (el) el.style.display = 'none';
            })();
            break;
        case 'receiveScreenshot':
            if (window.adminPanelInstance) {
                window.adminPanelInstance.screenshotImage = payload;
            }
            break;
        case 'notification':
            if (payload && payload.text) {
                vuexstore.commit('createNotification', { type: payload.type || 'info', text: payload.text });
            }
            break;
    }
});
document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        if (vuexstore.state.showWarnModal) {
            vuexstore.commit('setShowWarnModal', false);
            window.postNUI('closeWarnModal');
            return;
        }
        if (vuexstore.state.showDMReceiveModal) {
            vuexstore.commit('setShowDMReceiveModal', false);
            window.postNUI('closeDMReceiveModal');
            return;
        }
        if (vuexstore.state.showAnnouncementReceive) {
            vuexstore.commit('setShowAnnouncementReceive', false);
            return;
        }
        if (vuexstore.state.showQuickMenu) {
            vuexstore.commit('setShowQuickMenu', false);
            window.postNUI('closeQuickMenu');
        }
        if (vuexstore.state.showAdminPanel) {
            vuexstore.commit('setShowAdminPanel', false);
            window.postNUI('closeAdminPanel');
        }
    }
});