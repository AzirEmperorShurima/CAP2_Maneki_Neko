import { Router } from "express";
import { createFamily, generateInviteLink, sendInviteEmail, joinFamilyWeb, leaveFamily, getFamilyMembers, updateSharingSettings, addSharedResource, removeSharedResource } from "../controllers/family.js";

const familyRouter = Router();

familyRouter.get("/", (req, res) => {
  res.status(200).json({
    status: "success",
    message: "Welcome to the Maneki Neko Family API",
  });
});

familyRouter.post("/", createFamily);
familyRouter.get("/invite-link", generateInviteLink);
familyRouter.post("/invite", sendInviteEmail);
familyRouter.get("/join-web", joinFamilyWeb);
familyRouter.post("/leave", leaveFamily);
familyRouter.get("/members", getFamilyMembers);
familyRouter.put("/settings/sharing", updateSharingSettings);
familyRouter.post("/shared-resources", addSharedResource);
familyRouter.delete("/shared-resources", removeSharedResource);

export default familyRouter;
