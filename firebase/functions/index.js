const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getDatabase } = require('firebase-admin/database');

initializeApp();

const PLANS = {
  free: { maxMembers: 1 },
  team: { maxMembers: 5 },
  team_plus: { maxMembers: 20 },
  large_team: { maxMembers: null }
};

function requireAuth(request) {
  if (!request.auth || !request.auth.uid) throw new HttpsError('unauthenticated', 'Sign in to Palo first.');
  return request.auth.uid;
}

function requireAdmin(request) {
  requireAuth(request);
  if (!request.auth.token || request.auth.token.admin !== true) {
    throw new HttpsError('permission-denied', 'Palo admin access is required.');
  }
}

function validatePlan(planId) {
  if (!Object.prototype.hasOwnProperty.call(PLANS, planId)) throw new HttpsError('invalid-argument', 'Unknown Palo plan.');
  return PLANS[planId];
}

exports.createWorkspace = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = request.data || {};
  const name = String(input.name || '').trim();
  const engine = String(input.engine || '').trim();
  const engineVersion = String(input.engineVersion || '').trim();
  const repository = String(input.repository || '').trim();
  if (!name || !engine || !engineVersion || !repository) throw new HttpsError('invalid-argument', 'Workspace name, engine, version, and repository are required.');

  const db = getDatabase();
  const workspaceId = db.ref().push().key;
  const workspace = {
    id: workspaceId, name, owner_user_id: uid, plan_id: 'free', engine, engine_version: engineVersion,
    repository: { provider: 'github', full_name: repository },
    members: { [uid]: { role: 'owner', joined_at: Date.now() } },
    created_at: Date.now(), updated_at: Date.now()
  };
  const updates = {};
  updates[`workspaces/${workspaceId}`] = workspace;
  updates[`user_workspaces/${uid}/${workspaceId}`] = true;
  await db.ref().update(updates);
  return workspace;
});

exports.addWorkspaceMember = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = request.data || {};
  const workspaceId = String(input.workspaceId || '').trim();
  const memberUid = String(input.memberUid || '').trim();
  if (!workspaceId || !memberUid) throw new HttpsError('invalid-argument', 'workspaceId and memberUid are required.');

  const db = getDatabase();
  const workspaceRef = db.ref(`workspaces/${workspaceId}`);
  const result = await workspaceRef.transaction((workspace) => {
    if (!workspace) return workspace;
    const members = workspace.members || {};
    if (!members[uid] || members[uid].role !== 'owner') return workspace;
    if (members[memberUid]) return workspace;
    const plan = validatePlan(String(workspace.plan_id || 'free'));
    const count = Object.keys(members).length;
    if (plan.maxMembers !== null && count >= plan.maxMembers) return workspace;
    members[memberUid] = { role: 'member', joined_at: Date.now() };
    workspace.members = members;
    workspace.updated_at = Date.now();
    return workspace;
  });

  const workspace = result.snapshot.val();
  if (!workspace) throw new HttpsError('not-found', 'Workspace not found.');
  if (!workspace.members || !workspace.members[uid] || workspace.members[uid].role !== 'owner') throw new HttpsError('permission-denied', 'Only the workspace owner can add members.');
  if (!workspace.members[memberUid]) {
    const plan = validatePlan(String(workspace.plan_id || 'free'));
    if (plan.maxMembers === 1) throw new HttpsError('failed-precondition', 'Team access required. This project is currently using the Palo Free plan, which supports one person. Contact the workspace administrator to upgrade the plan before adding another person.');
    throw new HttpsError('failed-precondition', 'The workspace has reached its member limit.');
  }
  await db.ref(`user_workspaces/${memberUid}/${workspaceId}`).set(true);
  return { allowed: true, workspace };
});

exports.getWorkspaceAccess = onCall(async (request) => {
  const uid = requireAuth(request);
  const workspaceId = String((request.data || {}).workspaceId || '').trim();
  if (!workspaceId) throw new HttpsError('invalid-argument', 'workspaceId is required.');
  const snapshot = await getDatabase().ref(`workspaces/${workspaceId}`).get();
  if (!snapshot.exists()) throw new HttpsError('not-found', 'Workspace not found.');
  const workspace = snapshot.val();
  const member = workspace.members && workspace.members[uid];
  const plan = validatePlan(String(workspace.plan_id || 'free'));
  const memberCount = workspace.members ? Object.keys(workspace.members).length : 0;
  return { allowed: !!member, role: member ? member.role : null, plan_id: workspace.plan_id || 'free', member_count: memberCount, max_members: plan.maxMembers, message: member ? 'Access allowed.' : 'This Palo workspace is not shared with your account.' };
});

exports.setWorkspacePlan = onCall(async (request) => {
  requireAdmin(request);
  const input = request.data || {};
  const workspaceId = String(input.workspaceId || '').trim();
  const planId = String(input.planId || '').trim();
  validatePlan(planId);
  if (!workspaceId) throw new HttpsError('invalid-argument', 'workspaceId is required.');
  const ref = getDatabase().ref(`workspaces/${workspaceId}`);
  const snapshot = await ref.get();
  if (!snapshot.exists()) throw new HttpsError('not-found', 'Workspace not found.');
  const workspace = snapshot.val();
  const count = workspace.members ? Object.keys(workspace.members).length : 0;
  const limit = PLANS[planId].maxMembers;
  if (limit !== null && count > limit) throw new HttpsError('failed-precondition', 'The selected plan cannot contain the current number of members.');
  await ref.update({ plan_id: planId, updated_at: Date.now(), subscription: { plan_id: planId, updated_at: Date.now(), source: 'trusted_admin' } });
  return { workspaceId, planId, memberCount: count, maxMembers: limit };
});

exports.getAdminMetrics = onCall(async (request) => {
  requireAdmin(request);
  const root = (await getDatabase().ref('/').get()).val() || {};
  const users = root.users || {};
  const workspaces = root.workspaces || {};
  const userValues = Object.values(users);
  const workspaceValues = Object.values(workspaces);
  const activeSince = Math.floor(Date.now() / 1000) - (30 * 24 * 60 * 60);
  const usersByCountry = {};
  const usersByRegion = {};
  const workspacesByEngine = {};
  const plans = {};
  userValues.forEach((u) => {
    const country = String(u.country_code || 'unknown').toUpperCase();
    const region = String(u.region || 'unknown');
    usersByCountry[country] = (usersByCountry[country] || 0) + 1;
    usersByRegion[region] = (usersByRegion[region] || 0) + 1;
  });
  workspaceValues.forEach((w) => {
    const engine = String(w.engine || 'unknown');
    const plan = String(w.plan_id || 'free');
    workspacesByEngine[engine] = (workspacesByEngine[engine] || 0) + 1;
    plans[plan] = (plans[plan] || 0) + 1;
  });
  return {
    total_users: userValues.length,
    active_users: userValues.filter((u) => Number(u.last_seen_at || 0) >= activeSince).length,
    total_workspaces: workspaceValues.length,
    paid_workspaces: workspaceValues.filter((w) => String(w.plan_id || 'free') !== 'free').length,
    users_by_country: usersByCountry,
    users_by_region: usersByRegion,
    workspaces_by_engine: workspacesByEngine,
    plans
  };
});
