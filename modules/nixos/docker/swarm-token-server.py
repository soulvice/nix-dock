#!/usr/bin/env python3

import subprocess
import json
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
import logging
from urllib.parse import urlparse
import urllib.request
import urllib.error
import threading
import time
import os

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ManagerRegistry:
    """Registry for tracking other manager nodes"""
    def __init__(self):
        self.managers = []
        self.health_cache = {}
        self.cache_ttl = 30  # Cache health results for 30 seconds
        self.load_managers()

    def load_managers(self):
        """Load manager nodes from environment variable"""
        managers_env = os.environ.get('SWARM_MANAGERS', '')
        if managers_env:
            self.managers = [m.strip() for m in managers_env.split(',') if m.strip()]
            logger.info(f"Loaded {len(self.managers)} manager nodes: {self.managers}")
        else:
            logger.info("No other managers configured (SWARM_MANAGERS not set)")

    def check_manager_health(self, manager_url, timeout=5):
        """Check health of a single manager"""
        try:
            health_url = f"http://{manager_url}/health"
            req = urllib.request.Request(health_url)
            with urllib.request.urlopen(req, timeout=timeout) as response:
                if response.status == 200:
                    data = json.loads(response.read().decode())
                    return {
                        'url': manager_url,
                        'status': 'healthy',
                        'swarm': data.get('swarm', 'unknown'),
                        'response_time': time.time()
                    }
                else:
                    return {
                        'url': manager_url,
                        'status': 'unhealthy',
                        'error': f'HTTP {response.status}',
                        'response_time': time.time()
                    }
        except urllib.error.URLError as e:
            return {
                'url': manager_url,
                'status': 'unreachable',
                'error': str(e),
                'response_time': time.time()
            }
        except Exception as e:
            return {
                'url': manager_url,
                'status': 'error',
                'error': str(e),
                'response_time': time.time()
            }

    def get_all_manager_health(self):
        """Get health status of all managers including self"""
        results = []
        current_time = time.time()

        # Check cache first
        for manager in self.managers:
            cached = self.health_cache.get(manager)
            if cached and (current_time - cached['response_time']) < self.cache_ttl:
                results.append(cached)
            else:
                health = self.check_manager_health(manager)
                self.health_cache[manager] = health
                results.append(health)

        return results

# Global manager registry
manager_registry = ManagerRegistry()

class SwarmTokenHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """Override to use our logger"""
        logger.info(format % args)

    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path

        try:
            if path == '/health':
                self.handle_health()
            elif path == '/health/all':
                self.handle_health_all()
            elif path == '/swarm/worker':
                self.handle_worker_token()
            elif path == '/swarm/manager':
                self.handle_manager_token()
            elif path == '/swarm/nodes':
                self.handle_swarm_nodes()
            elif path == '/managers':
                self.handle_managers_list()
            elif path == '/managers/reload':
                self.handle_managers_reload()
            else:
                self.send_error(404, "Not Found")
        except Exception as e:
            logger.error(f"Error handling request {path}: {e}")
            self.send_error(500, "Internal Server Error")

    def handle_health(self):
        """Health check endpoint"""
        try:
            # Check if Docker is running and swarm is active
            result = subprocess.run(['docker', 'info', '--format', '{{.Swarm.LocalNodeState}}'],
                                  capture_output=True, text=True, timeout=5)

            if result.returncode == 0 and result.stdout.strip() == 'active':
                self.send_json_response({'status': 'healthy', 'swarm': 'active'})
            else:
                self.send_json_response({'status': 'unhealthy', 'swarm': 'inactive'}, status=503)

        except subprocess.TimeoutExpired:
            self.send_json_response({'status': 'unhealthy', 'error': 'docker timeout'}, status=503)
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            self.send_json_response({'status': 'unhealthy', 'error': str(e)}, status=503)

    def handle_health_all(self):
        """Global health check for all manager nodes"""
        try:
            # Get local health first
            local_health = self.get_local_health()

            # Get other managers' health
            other_managers = manager_registry.get_all_manager_health()

            # Combine results
            all_managers = [local_health] + other_managers

            # Calculate overall status
            healthy_count = sum(1 for m in all_managers if m['status'] == 'healthy')
            total_count = len(all_managers)

            overall_status = 'healthy' if healthy_count == total_count else 'degraded'
            if healthy_count == 0:
                overall_status = 'unhealthy'

            response = {
                'overall_status': overall_status,
                'healthy_managers': healthy_count,
                'total_managers': total_count,
                'managers': all_managers,
                'timestamp': time.time()
            }

            status_code = 200 if overall_status == 'healthy' else 503
            self.send_json_response(response, status=status_code)

        except Exception as e:
            logger.error(f"Global health check failed: {e}")
            self.send_json_response({'error': 'Global health check failed', 'details': str(e)}, status=500)

    def get_local_health(self):
        """Get local node health status"""
        try:
            result = subprocess.run(['docker', 'info', '--format', '{{.Swarm.LocalNodeState}}'],
                                  capture_output=True, text=True, timeout=5)

            if result.returncode == 0 and result.stdout.strip() == 'active':
                return {
                    'url': 'localhost',
                    'status': 'healthy',
                    'swarm': 'active',
                    'node_type': 'local',
                    'response_time': time.time()
                }
            else:
                return {
                    'url': 'localhost',
                    'status': 'unhealthy',
                    'swarm': 'inactive',
                    'node_type': 'local',
                    'response_time': time.time()
                }
        except Exception as e:
            return {
                'url': 'localhost',
                'status': 'error',
                'error': str(e),
                'node_type': 'local',
                'response_time': time.time()
            }

    def handle_worker_token(self):
        """Get worker join token"""
        try:
            result = subprocess.run(['docker', 'swarm', 'join-token', 'worker', '-q'],
                                  capture_output=True, text=True, timeout=10)

            if result.returncode == 0:
                token = result.stdout.strip()
                self.send_json_response({'token': token, 'type': 'worker'})
            else:
                logger.error(f"Failed to get worker token: {result.stderr}")
                self.send_json_response({'error': 'Failed to get worker token'}, status=500)

        except subprocess.TimeoutExpired:
            self.send_json_response({'error': 'Docker command timeout'}, status=500)
        except Exception as e:
            logger.error(f"Worker token error: {e}")
            self.send_json_response({'error': str(e)}, status=500)

    def handle_manager_token(self):
        """Get manager join token"""
        try:
            result = subprocess.run(['docker', 'swarm', 'join-token', 'manager', '-q'],
                                  capture_output=True, text=True, timeout=10)

            if result.returncode == 0:
                token = result.stdout.strip()
                self.send_json_response({'token': token, 'type': 'manager'})
            else:
                logger.error(f"Failed to get manager token: {result.stderr}")
                self.send_json_response({'error': 'Failed to get manager token'}, status=500)

        except subprocess.TimeoutExpired:
            self.send_json_response({'error': 'Docker command timeout'}, status=500)
        except Exception as e:
            logger.error(f"Manager token error: {e}")
            self.send_json_response({'error': str(e)}, status=500)

    def handle_swarm_nodes(self):
        """Get swarm nodes information"""
        try:
            result = subprocess.run(['docker', 'node', 'ls', '--format', 'json'],
                                  capture_output=True, text=True, timeout=10)

            if result.returncode == 0:
                nodes = []
                for line in result.stdout.strip().split('\n'):
                    if line:
                        try:
                            node = json.loads(line)
                            nodes.append(node)
                        except json.JSONDecodeError:
                            continue

                self.send_json_response({'nodes': nodes, 'count': len(nodes)})
            else:
                logger.error(f"Failed to get swarm nodes: {result.stderr}")
                self.send_json_response({'error': 'Failed to get swarm nodes'}, status=500)

        except subprocess.TimeoutExpired:
            self.send_json_response({'error': 'Docker command timeout'}, status=500)
        except Exception as e:
            logger.error(f"Swarm nodes error: {e}")
            self.send_json_response({'error': str(e)}, status=500)

    def handle_managers_list(self):
        """List configured manager nodes"""
        try:
            response = {
                'configured_managers': manager_registry.managers,
                'manager_count': len(manager_registry.managers),
                'cache_ttl': manager_registry.cache_ttl
            }
            self.send_json_response(response)
        except Exception as e:
            logger.error(f"Managers list error: {e}")
            self.send_json_response({'error': str(e)}, status=500)

    def handle_managers_reload(self):
        """Reload manager configuration"""
        try:
            old_count = len(manager_registry.managers)
            manager_registry.load_managers()
            manager_registry.health_cache.clear()  # Clear cache after reload

            response = {
                'message': 'Manager configuration reloaded',
                'old_count': old_count,
                'new_count': len(manager_registry.managers),
                'managers': manager_registry.managers
            }
            self.send_json_response(response)
        except Exception as e:
            logger.error(f"Managers reload error: {e}")
            self.send_json_response({'error': str(e)}, status=500)

    def send_json_response(self, data, status=200):
        """Send JSON response"""
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        response = json.dumps(data, indent=2)
        self.wfile.write(response.encode('utf-8'))

def main():
    """Main server function"""
    host = os.environ.get('SWARM_TOKEN_HOST', '0.0.0.0')
    port = int(os.environ.get('SWARM_TOKEN_PORT', '3535'))

    logger.info(f"Starting Swarm Token Server on {host}:{port}")
    logger.info(f"Manager nodes: {len(manager_registry.managers)} configured")

    # Create and start server
    server_address = (host, port)
    httpd = HTTPServer(server_address, SwarmTokenHandler)

    try:
        logger.info(f"Server running at http://{host}:{port}/")
        logger.info("Available endpoints:")
        logger.info("  GET /health - Local health check")
        logger.info("  GET /health/all - Global health check (all managers)")
        logger.info("  GET /swarm/worker - Get worker join token")
        logger.info("  GET /swarm/manager - Get manager join token")
        logger.info("  GET /swarm/nodes - List all swarm nodes")
        logger.info("  GET /managers - List configured manager nodes")
        logger.info("  GET /managers/reload - Reload manager configuration")
        logger.info("")
        logger.info("Environment variables:")
        logger.info("  SWARM_TOKEN_HOST - Server bind address (default: 0.0.0.0)")
        logger.info("  SWARM_TOKEN_PORT - Server port (default: 3535)")
        logger.info("  SWARM_MANAGERS - Comma-separated list of other manager URLs")
        logger.info("    Example: SWARM_MANAGERS='192.168.1.10:3535,192.168.1.11:3535'")
        httpd.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down server...")
        httpd.server_close()
    except Exception as e:
        logger.error(f"Server error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
