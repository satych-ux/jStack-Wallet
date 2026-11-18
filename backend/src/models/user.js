/** The user as the API shows it: never the password. */
function toUserResponse(user) {
  return { id: user.id, name: user.name, email: user.email };
}

module.exports = { toUserResponse };
