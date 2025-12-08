import { Router } from "express";
import { createFamily, generateInviteLink, sendInviteEmail, joinFamilyWeb, leaveFamily, getFamilyMembers, updateSharingSettings, addSharedResource, removeSharedResource, addFamilyMember, removeFamilyMember, getFamilySpendingSummary, getFamilyUserBreakdown, getFamilyTopCategories, getFamilyTopSpender, dissolveFamily } from "../controllers/familyController.js";
import { jwtAuth } from "../middlewares/auth.js";

const familyRouter = Router();

familyRouter.get("/", (req, res) => {
  res.status(200).json({
    status: "success",
    message: "Welcome to the Maneki Neko Family API",
  });
});

familyRouter.get("/join-web", joinFamilyWeb);
familyRouter.use(jwtAuth)
familyRouter.post("/", createFamily);
familyRouter.get("/invite-link", generateInviteLink);
familyRouter.post("/invite", sendInviteEmail);

familyRouter.post("/leave", leaveFamily);
familyRouter.get("/members", getFamilyMembers);
// familyRouter.put("/settings/sharing", updateSharingSettings);
// familyRouter.post("/shared-resources", addSharedResource);
// familyRouter.delete("/shared-resources", removeSharedResource);
familyRouter.post("/dissolve", dissolveFamily);
// familyRouter.post("/members/add", addFamilyMember);
familyRouter.post("/members/remove", removeFamilyMember);

familyRouter.get("/analytics/summary", getFamilySpendingSummary);
familyRouter.get("/analytics/user-breakdown", getFamilyUserBreakdown);
familyRouter.get("/analytics/top-categories", getFamilyTopCategories);
familyRouter.get("/analytics/top-spender", getFamilyTopSpender);

export default familyRouter;
