/**
 * Role-based access control. Must run after the auth middleware.
 *
 * @param {string[]} allowedRoles - e.g. checkRole(['owner'])
 */
function checkRole(allowedRoles) {
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];

  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required' });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Insufficient permissions for this action' });
    }

    return next();
  };
}

module.exports = { checkRole };
