package conversation_msg

import (
	"context"
	"errors"
	"time"

	"github.com/openimsdk/openim-sdk-core/v3/pkg/constant"
	msg_edit "github.com/openimsdk/openim-sdk-core/v3/pkg/proto/msg_edit"
	"github.com/openimsdk/openim-sdk-core/v3/pkg/utils"
	"github.com/openimsdk/openim-sdk-core/v3/sdk_struct"
	"github.com/openimsdk/protocol/sdkws"
	"github.com/openimsdk/tools/log"
)

// editOneMessage 編輯單條消息的內部實現
func (c *Conversation) editOneMessage(ctx context.Context, conversationID string, seq int64, newContent, editReason string) error {
	// 1. 驗證參數
	if conversationID == "" || seq <= 0 || newContent == "" {
		return errors.New("invalid parameters for edit message")
	}

	// 2. 獲取會話信息
	conversation, err := c.db.GetConversation(ctx, conversationID)
	if err != nil {
		log.ZError(ctx, "GetConversation failed", err, "conversationID", conversationID)
		return err
	}

	// 3. 獲取消息
	message, err := c.db.GetMessageBySeq(ctx, conversationID, seq)
	if err != nil {
		log.ZError(ctx, "GetMessageBySeq failed", err, "conversationID", conversationID, "seq", seq)
		return err
	}

	// 4. 驗證權限（只有發送者可以編輯）
	if message.SendID != c.loginUserID {
		// 如果是群組，檢查是否為管理員
		if conversation.ConversationType == constant.ReadGroupChatType {
			groupAdmins, err := c.db.GetGroupMemberOwnerAndAdminDB(ctx, conversation.GroupID)
			if err != nil {
				return err
			}
			isAdmin := false
			for _, member := range groupAdmins {
				if member.UserID == c.loginUserID {
					isAdmin = true
					break
				}
			}
			if !isAdmin {
				return errors.New("only message sender or group admin can edit message")
			}
		} else {
			return errors.New("only message sender can edit message")
		}
	}

	// 5. 檢查編輯時間限制（24小時）
	editTimeLimit := int64(86400) // 24 hours in seconds
	currentTime := time.Now().Unix()
	if currentTime-message.SendTime > editTimeLimit {
		return errors.New("message edit time limit exceeded")
	}

	// 6. 調用服務器 API 編輯消息
	err = c.editMessageOnServer(ctx, conversationID, seq, newContent, editReason)
	if err != nil {
		log.ZError(ctx, "editMessageOnServer failed", err)
		return err
	}

	// 7. 更新本地數據庫
	message.Content = newContent
	message.Ex = editReason // 使用 Ex 字段存儲編輯原因
	err = c.db.UpdateMessage(ctx, conversationID, message)
	if err != nil {
		log.ZError(ctx, "UpdateMessage failed", err)
		return err
	}

	log.ZInfo(ctx, "message edited successfully", "conversationID", conversationID, "seq", seq)
	return nil
}

// validateEditPermission 驗證編輯權限
func (c *Conversation) validateEditPermission(ctx context.Context, conversationID string, seq int64) (bool, string, error) {
	resp, err := c.validateEditPermissionOnServer(ctx, conversationID, seq)
	if err != nil {
		return false, "", err
	}

	if resp.Data != nil {
		return resp.Data.CanEdit, resp.Data.Reason, nil
	}

	return false, "permission check failed", nil
}

// getMessageEditHistory 獲取消息編輯歷史
func (c *Conversation) getMessageEditHistory(ctx context.Context, conversationID string, seq int64) ([]*msg_edit.MessageEditRecord, error) {
	resp, err := c.getMessageEditHistoryFromServer(ctx, conversationID, seq)
	if err != nil {
		return nil, err
	}

	return resp.EditHistory, nil
}

// getEditableMessages 獲取可編輯的消息列表
func (c *Conversation) getEditableMessages(ctx context.Context, conversationID string, pageNumber, showNumber int32) ([]*msg_edit.EditableMessageInfo, error) {
	resp, err := c.getEditableMessagesFromServer(ctx, conversationID, pageNumber, showNumber)
	if err != nil {
		return nil, err
	}

	return resp.Messages, nil
}

// doEditMsg 處理編輯消息通知
func (c *Conversation) doEditMsg(ctx context.Context, msg *sdkws.MsgData) error {
	var editNotification msg_edit.EditNotificationData

	// 解析通知內容
	if err := utils.UnmarshalNotificationElem(msg.Content, &editNotification); err != nil {
		log.ZWarn(ctx, "unmarshal edit notification failed", err, "msg", msg)
		return err
	}

	log.ZDebug(ctx, "received edit notification", "notification", &editNotification)

	// 獲取被編輯的消息
	editedMsg, err := c.db.GetMessageBySeq(ctx, editNotification.ConversationId, editNotification.Seq)
	if err != nil {
		log.ZError(ctx, "GetMessageBySeq failed", err, "conversationID", editNotification.ConversationId, "seq", editNotification.Seq)
		return err
	}

	// 更新消息內容
	editedMsg.Content = editNotification.NewContent
	editedMsg.Ex = "edited" // 標記為已編輯

	// 更新本地數據庫
	err = c.db.UpdateMessage(ctx, editNotification.ConversationId, editedMsg)
	if err != nil {
		log.ZError(ctx, "UpdateMessage failed", err)
		return err
	}

	// 構建通知消息
	notificationMsg := &sdk_struct.MsgStruct{
		ClientMsgID: editedMsg.ClientMsgID,
		ServerMsgID: editedMsg.ServerMsgID,
		Seq:         editNotification.Seq,
		Content:     editNotification.NewContent,
		ContentType: constant.Text, // 使用文本類型，添加編輯標記
		SendTime:    editNotification.EditTime,
		SendID:      editNotification.EditorUserId,
		Ex:          "edited", // 標記為已編輯
	}

	// 觸發消息更新回調
	// 注意：實際的回調機制需要根據 SDK 的事件系統來實現
	log.ZInfo(ctx, "message edit notification processed", "msg", notificationMsg)

	return nil
}