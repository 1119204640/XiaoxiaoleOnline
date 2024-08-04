return {
	
	daemon = true,
	logpath = "/root/workspace/git_project/XiaoxiaoleOnline/server/log/skynet_log",
	auto_relog = true,
	sighup_file = "/root/workspace/git_project/XiaoxiaoleOnline/server/sighup_file",
	
	cluster = {
		node1 = "127.0.0.1:7771",
		--node2 = "127.0.0.1:7772",
	},

	-- 代理服务管理服,唯一服,配置它在哪个节点启动
	agentmgr = {node = "node1"},

	-- 管理员服,唯一服,配置它在哪个节点启动
	admin = {node = "node1", port = 8888},

	log = {node = "node1"},

	scene = {
		node1 = {1001, 1002},
		--node2 = {1003},
	},
	
	-- 节点1
	node1 = {
		gateway = {
			[1] = {port = 8001},
			[2] = {port = 8002},
		},
		login = {
			[1] = {},
			[2] = {},
		},
	},

	-- 节点2
	node2 = {
		gateway = {
			[1] = {port = 8011},
			[2] = {port = 8022},
		},
		login = {
			[1] = {},
			[2] = {},
		},
	},
}
